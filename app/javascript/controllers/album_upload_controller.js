import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["area", "input", "preview", "grid", "count"]

  // クリック処理は <label> の自然な転送に委ねるため openPicker は不要
  // （e.preventDefault() を呼ぶと iOS が trusted gesture と判断せず input.click() を無視する）

  preview() {
    this.#showFiles(this.inputTarget.files)
  }

  dragover(e) {
    e.preventDefault()
    this.areaTarget.classList.add("album-upload-area--dragover")
  }

  dragleave() {
    this.areaTarget.classList.remove("album-upload-area--dragover")
  }

  drop(e) {
    e.preventDefault()
    this.areaTarget.classList.remove("album-upload-area--dragover")

    const files = [...e.dataTransfer.files].filter(f => f.type.startsWith("image/"))
    if (!files.length) return

    const dt = new DataTransfer()
    files.forEach(f => dt.items.add(f))
    this.inputTarget.files = dt.files
    this.#showFiles(dt.files)
  }

  reset() {
    this.inputTarget.value = ""
    this.gridTarget.innerHTML = ""
    this.previewTarget.style.display = "none"
    this.areaTarget.style.display = "flex"
  }

  #showFiles(files) {
    if (!files.length) return

    this.gridTarget.innerHTML = ""
    ;[...files].forEach((file) => {
      const reader = new FileReader()
      reader.onload = (e) => {
        const thumb = document.createElement("div")
        thumb.className = "album-upload-thumb"
        thumb.innerHTML = `<img src="${e.target.result}" alt="" class="album-upload-thumb-img">`
        this.gridTarget.appendChild(thumb)
      }
      reader.readAsDataURL(file)
    })

    this.countTarget.textContent = `${files.length}枚選択中`
    this.areaTarget.style.display = "none"
    this.previewTarget.style.display = "block"
  }
}
