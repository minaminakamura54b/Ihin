import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    // 前回の開閉状態を復元
    const open = localStorage.getItem("devBarOpen") !== "false"
    this.contentTarget.classList.toggle("hidden", !open)
  }

  toggle() {
    const hidden = this.contentTarget.classList.toggle("hidden")
    localStorage.setItem("devBarOpen", !hidden)
  }
}
