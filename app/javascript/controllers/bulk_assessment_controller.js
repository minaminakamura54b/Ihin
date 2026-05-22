import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["itemList", "item", "addButton", "submitButton", "countText", "form"]
  static values = { maxItems: { type: Number, default: 5 }, remaining: { type: Number, default: 99 } }

  connect() {
    this.updateUI()
  }

  addItem() {
    const count = this.itemTargets.length
    if (count >= this.maxItemsValue) return
    if (count >= this.remainingValue && this.remainingValue < 99) return

    const template = this.buildItemTemplate(count)
    this.itemListTarget.insertAdjacentHTML("beforeend", template)
    this.updateUI()

    // Stimulus auto-registers new elements, but we need to scroll to it
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
    const max = Math.min(this.maxItemsValue, this.remainingValue < 99 ? this.remainingValue : this.maxItemsValue)

    if (this.hasAddButtonTarget) {
      this.addButtonTarget.classList.toggle("hidden", count >= max)
    }
    if (this.hasCountTextTarget) {
      this.countTextTarget.textContent = `現在 ${count}点 登録中`
    }
  }

  buildItemTemplate(index) {
    return `
      <div class="bulk-item-card" data-bulk-assessment-target="item">
        <div class="bulk-item-header">
          <h3 class="bulk-item-title">遺品 <span data-bulk-assessment-target="itemNumber">${index + 1}</span></h3>
          <button type="button" class="btn-icon btn-danger-ghost"
                  data-action="click->bulk-assessment#removeItem" title="削除">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="form-group">
          <label class="form-label">品物の名前（任意）</label>
          <input type="text" name="items[${index}][name]" class="form-input"
                 placeholder="例：腕時計、着物、カメラなど">
        </div>
        <div class="form-group">
          <label class="form-label">写真（最大5枚）</label>
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
      </div>
    `
  }
}
