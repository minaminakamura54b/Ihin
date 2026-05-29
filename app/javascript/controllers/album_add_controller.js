import { Controller } from "@hotwired/stimulus"

// アルバム詳細ページの思い出追加セクション
export default class extends Controller {
  static targets = ["checkbox", "count", "submit", "item"]

  updateCount() {
    const n = this.checkboxTargets.filter(cb => cb.checked).length
    this.countTarget.textContent = `${n}件選択中`
    this.submitTarget.disabled = n === 0
    // 選択中のカードを強調
    this.itemTargets.forEach(item => {
      const cb = item.querySelector("input[type='checkbox']")
      item.classList.toggle("album-add-item-selected", cb.checked)
    })
  }
}
