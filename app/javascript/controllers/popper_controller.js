import { Controller } from "@hotwired/stimulus"
import { createPopper } from "@popperjs/core"

// Connects to data-controller="popper"
export default class extends Controller {
  static targets = ["form", "tooltip"]

  connect() {
    this.formTarget.addEventListener("submit", this.submit.bind(this))
    this.documentHn = this.documentClick.bind(this)
    document.addEventListener("click", this.documentHn)
  }

  submit(event) {
    event.preventDefault()
    if (this.popper) {
      // Destroy and make the tooltip hidden.
      this.popper.destroy()
      this.tooltipTarget.classList.add("hidden")
      delete this.popper
    } else {
      // Create the tooltip.
      this.popper = createPopper(this.formTarget, this.tooltipTarget)
      this.tooltipTarget.classList.remove("hidden")
    }
    return false
  }

  documentClick(event) {
    if (this.popper && !this.element.contains(event.target)) {
      // Destroy and make the tooltip hidden.
      this.popper.destroy()
      this.tooltipTarget.classList.add("hidden")
      delete this.popper
    }
  }

  disconnect() {
    if (this.popper) this.popper.destroy()
    document.removeEventListener("click", this.documentHn)
  }
}
