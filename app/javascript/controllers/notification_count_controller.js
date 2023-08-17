import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notification-count"
export default class extends Controller {
  connect() {
    // Call the handler.
    this.updateCount()

    // Call the handler every 20 seconds.
    this.interval = setInterval(() => {
      this.updateCount()
    }, 20000)
  }

  disconnect() {
    // Stop calling the handler every 20 seconds.
    clearInterval(this.interval)
  }

  updateCount() {
    // Get the count from the server.
    fetch(`/ajax/notification_count/${this.element.dataset.did}`)
      .then(response => response.json())
      .then(data => {
        // Set the element's text to the count.
        this.element.textContent = data.count
      })
  }
}
