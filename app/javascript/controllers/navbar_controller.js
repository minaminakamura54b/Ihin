import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    this.menuTarget.classList.toggle("open")
  }

  close() {
    this.menuTarget.classList.remove("open")
  }
}
