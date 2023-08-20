import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="did-switch-remapper"
export default class extends Controller {
  connect() {
    // Return now if the path starts with /home.
    if (window.location.pathname.startsWith("/home")) return

    // Get the current URL.
    const url = new URL(window.location.href)

    // Add authed_did to the query string.
    url.searchParams.set("authed_did", this.element.dataset.did)

    // Replace the link href with the new URL.
    this.element.href = url.toString()
  }
}
