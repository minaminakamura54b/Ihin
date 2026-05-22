import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "overlay"]

  submit(event) {
    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "査定中..."
    this.overlayTarget.classList.remove("hidden")
  }
}
