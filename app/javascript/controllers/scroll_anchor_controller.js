import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scroll-anchor"
export default class extends Controller {
  connect() {
    // Scroll to this element.
    this.element.scrollIntoView({ behavior: "smooth" })
  }
}
