import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.close(), 5000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  close() {
    this.element.style.animation = "slideOut 0.3s ease forwards"
    setTimeout(() => this.element.remove(), 300)
  }
}
