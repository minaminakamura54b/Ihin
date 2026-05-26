import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["itemList", "item", "addButton", "submitButton", "countText", "form"]
  static values = { maxItems: { type: Number, default: 5 }, remaining: { type: Number, default: 99 } }

  connect() {
    this.updateUI()
  }

  addItem() {
    const count = this.itemTargets.length

    // 5点の絶対上限チェック
    if (count >= this.maxItemsValue) return

    // ゲストの残り件数チェック（クリック時のみ判定）
    if (this.remainingValue < 99 && count >= this.remainingValue) {
      alert(`残り${this.remainingValue}点まで無料で査定できます。無料登録すると制限なくご利用いただけます。`)
      return
    }

    const template = this.buildItemTemplate(count)
    this.itemListTarget.insertAdjacentHTML("beforeend", template)
    this.updateUI()

    const newItem = this.itemTargets[this.itemTargets.length - 1]
    newItem.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  removeItem(event) {
    const item = event.currentTarget.closest("[data-bulk-assessment-target='item']")
    item.remove()
    this.reindexItems()
    this.updateUI()
  }

  reindexItems() {
    this.itemTargets.forEach((item, i) => {
      const numEl = item.querySelector("[data-bulk-assessment-target='itemNumber']")
      if (numEl) numEl.textContent = i + 1

      // Update all input names with new index
      item.querySelectorAll("input").forEach(input => {
        input.name = input.name.replace(/items\[\d+\]/, `items[${i}]`)
      })

      // Show/hide remove button for first item
      const removeBtn = item.querySelector("[data-action*='removeItem']")
      if (removeBtn) removeBtn.classList.toggle("hidden", i === 0)
    })
  }

  updateUI() {
    const count = this.itemTargets.length

    // ボタン表示は5点上限のみで判定（ゲストの残り件数はクリック時に判定）
    if (this.hasAddButtonTarget) {
      this.addButtonTarget.classList.toggle("hidden", count >= this.maxItemsValue)
    }
    if (this.hasCountTextTarget) {
      this.countTextTarget.textContent = `現在 ${count}点 登録中（最大5点）`
    }
  }

  buildItemTemplate(index) {
    return `
      <div class="bulk-item-card" data-bulk-assessment-target="item">
        <div class="bulk-item-header">
          <h3 class="bulk-item-title">商品 <span data-bulk-assessment-target="itemNumber">${index + 1}</span></h3>
          <button type="button" class="btn-icon btn-danger-ghost"
                  data-action="click->bulk-assessment#removeItem" title="削除">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="form-group">
          <label class="form-label">商品名（任意）</label>
          <input type="text" name="items[${index}][name]" class="form-input"
                 placeholder="例：腕時計、着物、カメラなど">
        </div>
        <div class="form-group">
          <label class="form-label">この商品の写真（1〜5枚）</label>
          <div class="upload-area upload-area-sm" data-controller="item-form"
               data-action="dragover->item-form#dragOver drop->item-form#drop"
               data-item-form-target="uploadArea">
            <div class="upload-placeholder" data-item-form-target="placeholder">
              <i class="fas fa-camera upload-icon"></i>
              <p>タップして写真を選択</p>
              <p class="upload-hint">複数枚可・ドラッグ&ドロップも可</p>
            </div>
            <div class="upload-preview hidden" data-item-form-target="preview">
              <div class="preview-grid" data-item-form-target="previewGrid"></div>
            </div>
            <input type="file" name="items[${index}][photos][]"
                   accept="image/*" multiple class="upload-input"
                   data-action="change->item-form#preview"
                   data-item-form-target="fileInput">
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">メモ（任意）</label>
          <textarea name="items[${index}][memo]" class="form-input"
                    rows="2" maxlength="500"
                    placeholder="状態・入手経緯など気になることをメモしておけます"></textarea>
        </div>
      </div>
    `
  }
}
