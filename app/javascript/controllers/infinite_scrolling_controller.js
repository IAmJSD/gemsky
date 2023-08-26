import { Controller } from "@hotwired/stimulus"

const timeout = ms => new Promise(r => setTimeout(r, ms))

const backOffFetch = (url, options) => new Promise(async res => {
  let backOffSeconds = 1
  for (;;) {
    try {
      const response = await fetch(url, options)
      if (response.ok) return res(response)
      console.error(`Error fetching ${url}: ${response.status} ${response.statusText} - Backing off for ${backOffSeconds} seconds`)
      await timeout(backOffSeconds * 1000)
      if (backOffSeconds < 60) backOffSeconds *= 2
    } catch (e) {
      console.error(`Error fetching ${url}: ${e} - Backing off for ${backOffSeconds} seconds`)
      await timeout(backOffSeconds * 1000)
      if (backOffSeconds < 60) backOffSeconds *= 2
    }
  }
})

// Connects to data-controller="infinite-scrolling"
export default class extends Controller {
  static targets = ["results"]

  connect() {
    // Hook into the scroll event.
    this.scrollHn = this.scroll.bind(this)
    window.addEventListener("scroll", this.scrollHn)
  }

  disconnect() {
    window.removeEventListener("scroll", this.scrollHn)
  }

  async _loadMore() {
    // Set the loading flag.
    this.loading = true

    try {
      // Compose the URL.
      const url = new URL(this.element.dataset.requestPath, window.location.origin)
      url.searchParams.append("cursor", this.element.dataset.cursor)
      url.searchParams.append("did", this.element.dataset.did)

      // Fetch the next page.
      const response = await backOffFetch(url.toString(), {
        headers: {
          Accept: 'text/html',
        },
      })

      // Get the HTML.
      const html = await response.text()

      // Parse the HTML.
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, "text/html")

      // Get __scroller__ from the new page.
      const newResponseData = doc.getElementById("__scroller__").dataset

      // Update the cursor.
      this.element.dataset.cursor = newResponseData.cursor

      // Put the contents of __payload__ into the results target.
      this.resultsTarget.insertAdjacentHTML("beforeend", doc.getElementById("__payload__").innerHTML)
    } finally {
      // Allow loading again.
      this.loading = false
    }
  }

  scroll() {
    // Check if we are loading.
    if (this.loading) return

    // Find if we have scrolled to 3000px from the bottom.
    const scrolledToBottom = window.innerHeight + window.scrollY >= document.body.offsetHeight - 3000
    if (scrolledToBottom) {
      // Load more.
      this._loadMore()
    }
  }
}
