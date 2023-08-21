import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="composer"
export default class extends Controller {
  connect() {
    this.element.addEventListener("submit", this.submit.bind(this))
  }

  submit(event) {
    event.preventDefault()
    // TODO: Gather more context.
    return false
  }
}
