import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="subtle-link"
export default class extends Controller {
  connect() {
    // Set the tab index.
    this.element.tabIndex = 0

    // Set the aria information to signify that this will redirect.
    this.element.setAttribute("role", "link")

    // Handle the click and key events.
    this.element.addEventListener("click", this.click.bind(this))
    this.element.addEventListener("keydown", this.keydown.bind(this))
  }

  _ignoredClick(e) {
    let target = e.target
    while (target) {
      let v = null
      try {
        v = target.getAttribute("data-image-gallery-item")
      } catch {}
      if (target.tagName === "A" || target.tagName === "BUTTON" || v !== null) {
        return true
      }
      target = target.parentNode
    }
    return false
  }

  click(e) {
    // Handle ignored clicks.
    if (this._ignoredClick(e)) return

    // Visit within Turbo.
    Turbo.visit(this.element.dataset.href)
  }

  keydown(e) {
    // Handle ignored clicks.
    if (this._ignoredClick(e)) return

    // Handle the enter key.
    if (e.key === "Enter") {
      // Visit within Turbo.
      Turbo.visit(this.element.dataset.href)
    }
  }
}
