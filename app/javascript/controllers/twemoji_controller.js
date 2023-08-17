import { Controller } from "@hotwired/stimulus"
import twemoji from "twemoji"

// Connects to data-controller="twemoji"
export default class extends Controller {
  connect() {
    twemoji.parse(this.element)
  }
}
