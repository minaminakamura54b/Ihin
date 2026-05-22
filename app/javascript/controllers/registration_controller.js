import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["addressSection"]

  connect() {
    this.toggleAddress()
  }

  toggleAddress() {
    const role = this.element.querySelector("select[name*='role']").value
    this.addressSectionTarget.style.display = role === "family" ? "" : "none"
  }
}
