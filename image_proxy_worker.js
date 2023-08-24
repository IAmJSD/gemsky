// Defines the regex for the proxy.
const ROUTE_REGEX = /^\/([^\/]+)\/([^\/]+)\/([^\/]+)$/

export default {
  async fetch(request) {
    // Match the request path.
    const reqUrl = new URL(request.url)
    const m = reqUrl.pathname.match(ROUTE_REGEX)

    // Handle if there was no match or this isn't a GET.
    if (!m || request.method !== "GET") {
      return new Response("Not Found", {
        status: 404,
      })
    }

    // Get each part.
    const hostname = decodeURIComponent(m[1])
    const did = decodeURIComponent(m[2])
    const cid = decodeURIComponent(m[3])

    // Go ahead and try and get width/height from the URL.
    const image = {}
    let w = Number(reqUrl.searchParams.get("w"))
    if (!Number.isNaN(w)) image.width = w
    let h = Number(reqUrl.searchParams.get("h"))
    if (Number.isNaN(h)) image.height = h

    // Try and turn the hostname into a URL.
    let url
    try {
      url = new URL(`https://${hostname}`)
    } catch {
      return new Response("Invalid Hostname", {
        status: 400,
      })
    }

    // Set the path to /xrpc/com.atproto.sync.getBlob.
    url.pathname = "/xrpc/com.atproto.sync.getBlob"

    // Set the search params.
    url.searchParams.set("did", did)
    url.searchParams.set("cid", cid)

    // Make the request and cache it in Cloudflare.
    const res = await fetch(url.toString(), {
      cf: {
        cacheTtl: 60 * 60 * 24,
        cacheEverything: true,
        image,
      },
    })

    // Handle if the request failed.
    if (!res.ok) {
      return new Response("Not Found", {
        status: 404,
      })
    }

    // Return the response.
    const r2 = new Response(res.body, res)
    r2.headers.append("Access-Control-Allow-Origin", "*")
    return r2
  },
}
