import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dialog"
export default class extends Controller {
  connect() {
    this.clickHandler = this.closeDialogIfClicked.bind(this)
    this.element.addEventListener("click", this.clickHandler)
    this.turboHandler = this.closeDialog.bind(this)
    document.addEventListener("turbo:before-cache", this.turboHandler)
  }

  disconnect() {
    this.element.removeEventListener("click", this.clickHandler)
    document.removeEventListener("turbo:before-cache", this.turboHandler)
  }

  closeDialog() {
    this.element.close()
  }

  closeDialogIfClicked(e) {
    if (e.target == this.element) {
      this.closeDialog()
    }
  }
}
