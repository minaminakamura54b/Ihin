import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["shareModal", "stopModal", "form", "urlInput", "copyLabel", "activeBox", "shareBtn"]
  static values  = { url: String, togglePath: String, shared: Boolean }

  // 共有開始モーダルを開く
  openShareModal() {
    this.shareModalTarget.classList.remove("hidden")
  }

  // 共有停止モーダルを開く
  stopShare() {
    this.stopModalTarget.classList.remove("hidden")
  }

  // モーダルを閉じる
  closeModal() {
    if (this.hasShareModalTarget) this.shareModalTarget.classList.add("hidden")
    if (this.hasStopModalTarget)  this.stopModalTarget.classList.add("hidden")
  }

  // 「共有する」確定 → フォーム送信
  confirmShare() {
    this.closeModal()
    this.formTarget.submit()
  }

  // 「停止する」確定 → フォーム送信
  confirmStop() {
    this.closeModal()
    this.formTarget.submit()
  }

  // URLをクリップボードにコピー
  async copyUrl() {
    try {
      await navigator.clipboard.writeText(this.urlValue)
      this.copyLabelTarget.textContent = "コピーしました！"
      setTimeout(() => { this.copyLabelTarget.textContent = "URLをコピー" }, 2500)
    } catch {
      // クリップボードAPIが使えない場合はinputを選択
      this.urlInputTarget.select()
      document.execCommand("copy")
      this.copyLabelTarget.textContent = "コピーしました！"
      setTimeout(() => { this.copyLabelTarget.textContent = "URLをコピー" }, 2500)
    }
  }

  // モーダル外クリックで閉じる
  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) this.closeModal()
  }
}
