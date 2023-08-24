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

  click(e) {
    // Make sure this event is not over a link or button.
    let target = e.target
    while (target) {
      if (target.tagName === "A" || target.tagName === "BUTTON") {
        return
      }
      target = target.parentNode
    }

    // Visit within Turbo.
    Turbo.visit(this.element.dataset.href)
  }

  keydown(e) {
    // Make sure this event is not over a link or button.
    let target = e.target
    while (target) {
      if (target.tagName === "A" || target.tagName === "BUTTON") {
        return
      }
      target = target.parentNode
    }

    // Handle the enter key.
    if (e.key === "Enter") {
      // Visit within Turbo.
      Turbo.visit(this.element.dataset.href)
    }
  }
}
