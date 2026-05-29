import { Controller } from "@hotwired/stimulus"

// 思い出一覧の複数選択 → アルバム追加機能
export default class extends Controller {
  static targets = [
    "toggleBtn", "grid", "wrap", "checkLabel", "checkbox", "card",
    "bar", "barCount", "addBtn",
    "modal"
  ]

  connect() {
    this.selecting = false
  }

  // 選択モードON/OFF
  toggleMode() {
    this.selecting = !this.selecting
    if (this.selecting) {
      this.toggleBtnTarget.innerHTML = '<i class="fas fa-times"></i> キャンセル'
      this.toggleBtnTarget.classList.add("btn-active")
      this.checkLabelTargets.forEach(el => el.classList.remove("hidden"))
      this.barTarget.classList.remove("hidden")
    } else {
      this.cancel()
    }
  }

  // カードクリック：選択モード中はリンクを無効化してチェック切り替え
  cardClick(event) {
    if (!this.selecting) return
    event.preventDefault()
    const wrap = event.currentTarget.closest("[data-memory-select-target='wrap']")
    const cb = wrap.querySelector("input[type='checkbox']")
    cb.checked = !cb.checked
    wrap.classList.toggle("memory-card-selected", cb.checked)
    this.updateCount()
  }

  updateCount() {
    const count = this.checkedIds().length
    this.barCountTarget.textContent = `${count}件選択中`
    this.addBtnTarget.disabled = count === 0
  }

  openModal() {
    if (this.checkedIds().length === 0) return
    this.modalTarget.classList.remove("hidden")
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
  }

  // アルバムに追加してリロード
  async addToAlbum(event) {
    const url    = event.currentTarget.dataset.albumUrl
    const ids    = this.checkedIds()
    const btn    = event.currentTarget
    btn.disabled = true

    const form = new FormData()
    ids.forEach(id => form.append("memory_ids[]", id))
    // CSRF トークン取得
    const token = document.querySelector("meta[name='csrf-token']")?.content
    const res = await fetch(url, {
      method: "POST",
      headers: { "X-CSRF-Token": token, "Accept": "text/html" },
      body: form
    })
    if (res.ok) {
      this.closeModal()
      this.cancel()
      // 成功フラッシュ表示
      const albumName = btn.querySelector(".album-picker-name")?.textContent || "アルバム"
      this.showFlash(`${ids.length}件を「${albumName}」に追加しました`)
    } else {
      btn.disabled = false
      alert("追加に失敗しました。もう一度お試しください。")
    }
  }

  cancel() {
    this.selecting = false
    this.toggleBtnTarget.innerHTML = '<i class="fas fa-check-square"></i> 選択'
    this.toggleBtnTarget.classList.remove("btn-active")
    this.checkLabelTargets.forEach(el => el.classList.add("hidden"))
    this.checkboxTargets.forEach(cb => { cb.checked = false })
    this.wrapTargets.forEach(el => el.classList.remove("memory-card-selected"))
    this.barTarget.classList.add("hidden")
    this.addBtnTarget.disabled = true
    this.barCountTarget.textContent = "0件選択中"
  }

  checkedIds() {
    return this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)
  }

  showFlash(message) {
    const flash = document.createElement("div")
    flash.className = "flash flash-notice"
    flash.textContent = message
    document.body.prepend(flash)
    setTimeout(() => flash.remove(), 3000)
  }
}
