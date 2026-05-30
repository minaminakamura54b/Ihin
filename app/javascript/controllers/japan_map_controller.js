import { Controller } from "@hotwired/stimulus"

// 日本地図のホバー・クリック操作
// baseUrl が設定されている場合: baseUrl?prefecture=NAME へ遷移（index用）
// category が設定されている場合: ?step=3&category=X&prefecture=NAME へ遷移（search用）
export default class extends Controller {
  static targets = ["svg", "pref", "tooltip", "tooltipBg", "tooltipText", "hoverLabel"]
  static values  = { category: String, baseUrl: String, frame: String }

  hover(event) {
    const path = event.currentTarget
    path.classList.add("pref-hovered")
    const name = path.dataset.name
    if (this.hasHoverLabelTarget) {
      this.hoverLabelTarget.textContent = name
      this.hoverLabelTarget.classList.add("visible")
    }
    this.showTooltip(path, name)
  }

  unhover(event) {
    event.currentTarget.classList.remove("pref-hovered")
    if (this.hasHoverLabelTarget) {
      this.hoverLabelTarget.classList.remove("visible")
    }
    if (this.hasTooltipTarget) {
      this.tooltipTarget.style.display = "none"
    }
  }

  select(event) {
    const name = event.currentTarget.dataset.name
    if (!name) return

    // 地図上の選択ハイライト
    this.prefTargets.forEach(p => p.classList.remove("pref-selected"))
    event.currentTarget.classList.add("pref-selected")

    const url     = this.buildUrl(name)
    const frameId = this.hasFrameValue ? this.frameValue : "search-steps"
    const frame   = document.querySelector(`turbo-frame#${frameId}`)
    if (frame) {
      frame.src = url
    } else {
      window.location.href = url
    }
  }

  showTooltip(path, name) {
    if (!this.hasTooltipTarget) return
    try {
      const bbox = path.getBBox()
      const cx   = bbox.x + bbox.width / 2
      const cy   = bbox.y - 6
      const tw = 80, th = 24
      this.tooltipBgTarget.setAttribute("x",      cx - tw / 2)
      this.tooltipBgTarget.setAttribute("y",      cy - th)
      this.tooltipBgTarget.setAttribute("width",  tw)
      this.tooltipBgTarget.setAttribute("height", th)
      this.tooltipTextTarget.setAttribute("x", cx)
      this.tooltipTextTarget.setAttribute("y", cy - th / 2)
      this.tooltipTextTarget.textContent = name
      this.tooltipTarget.style.display = "block"
    } catch (_) { /* SVGがまだDOMにない場合は無視 */ }
  }

  buildUrl(prefecture) {
    if (this.hasBaseUrlValue) {
      // index 用: baseUrl?prefecture=NAME&category=X（既存パラメータを保持）
      const base = new URL(this.baseUrlValue, window.location.origin)
      const current = new URL(window.location.href)
      for (const [k, v] of current.searchParams) {
        if (k !== "prefecture" && k !== "page") base.searchParams.set(k, v)
      }
      base.searchParams.set("prefecture", prefecture)
      return base.toString()
    }
    // search 用: step=3&category=X&prefecture=NAME
    const base = new URL(window.location.href)
    base.searchParams.set("step",       "3")
    base.searchParams.set("category",   this.categoryValue)
    base.searchParams.set("prefecture", prefecture)
    return base.toString()
  }
}
