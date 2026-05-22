import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "placeholder", "preview", "previewGrid", "uploadArea"]

  preview(event) {
    const files = Array.from(event.target.files)
    if (files.length === 0) return

    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add("hidden")
    if (this.hasPreviewTarget) this.previewTarget.classList.remove("hidden")
    if (this.hasPreviewGridTarget) this.previewGridTarget.innerHTML = ""

    files.slice(0, 5).forEach(file => {
      const reader = new FileReader()
      reader.onload = (e) => {
        const img = document.createElement("img")
        img.src = e.target.result
        img.className = "preview-thumb"
        img.alt = file.name
        if (this.hasPreviewGridTarget) {
          this.previewGridTarget.appendChild(img)
        } else if (this.hasPreviewTarget) {
          this.previewTarget.innerHTML = `<img src="${e.target.result}" class="preview-image" alt="プレビュー">`
        }
      }
      reader.readAsDataURL(file)
    })
  }

  dragOver(event) {
    event.preventDefault()
    if (this.hasUploadAreaTarget) this.uploadAreaTarget.classList.add("drag-over")
  }

  drop(event) {
    event.preventDefault()
    if (this.hasUploadAreaTarget) this.uploadAreaTarget.classList.remove("drag-over")
    const files = event.dataTransfer.files
    if (files.length > 0) {
      const dt = new DataTransfer()
      Array.from(files).slice(0, 5).forEach(f => dt.items.add(f))
      if (this.hasFileInputTarget) {
        this.fileInputTarget.files = dt.files
        this.preview({ target: { files: dt.files } })
      }
    }
  }
}
