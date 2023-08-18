import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dialog-toggle"
export default class extends Controller {
  connect() {
    this.controls = this.element.getAttribute("aria-controls")
    this.element.addEventListener("submit", this.submit.bind(this))
  }

  submit(e) {
    e.preventDefault()
    document.getElementById(this.controls).showModal()
    return false
  }
}
