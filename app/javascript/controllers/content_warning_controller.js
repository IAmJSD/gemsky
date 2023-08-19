import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="content-warning"
export default class extends Controller {
  static targets = ["button", "content"]

  toggle(e) {
    e.preventDefault()

    // Get the state of the button.
    const isHidden = this.buttonTarget.getAttribute("aria-expanded") === "false"
    if (isHidden) {
      // Show the content.
      this.contentTarget.style.display = "block"
      this.buttonTarget.setAttribute("aria-expanded", "true")
      this.buttonTarget.textContent = "Hide Content"
    } else {
      // Hide the content.
      this.contentTarget.style.display = "none"
      this.buttonTarget.setAttribute("aria-expanded", "false")
      this.buttonTarget.textContent = "Show Content"
    }

    return false
  }
}
