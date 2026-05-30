import { Controller } from "@hotwired/stimulus"

// 問い合わせフォームの連絡方法切り替え
// ラジオボタンの選択に応じてメール/電話入力欄を動的に表示する
export default class extends Controller {
  static targets = ["emailField", "phoneField"]

  connect() {
    this.toggle()
  }

  // ラジオボタン変更時に呼ばれる
  toggle() {
    const selected = this.element.querySelector("input[name*='contact_type']:checked")
    if (!selected) return

    if (selected.value === "email") {
      // メールを選択
      this.emailFieldTarget.hidden = false
      this.phoneFieldTarget.hidden = true
      this.phoneFieldTarget.querySelector("input").value = ""
    } else {
      // 電話を選択
      this.emailFieldTarget.hidden = true
      this.phoneFieldTarget.hidden = false
      this.emailFieldTarget.querySelector("input").value = ""
    }
  }
}
