import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="submit-on-checkbox"
export default class extends Controller {
  static targets = ["checkbox", "form"]

  connect() {
    // Listen for changes to the checkbox targets.
    this.checkboxTargets.forEach(checkbox => {
      checkbox.addEventListener("change", this.change.bind(this))
    })
  }

  change() {
    this.formTarget.submit()
  }
}
