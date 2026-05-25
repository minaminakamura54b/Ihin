import { Controller } from "@hotwired/stimulus"

// 業種ごとの許可証ラベル
const LICENSE_LABELS = {
  estate_clearance:   "古物商許可証番号",
  buyback:            "古物商許可証番号",
  real_estate:        "宅建業免許番号",
  tax_accountant:     "税理士登録番号",
  judicial_scrivener: "司法書士登録番号",
}

export default class extends Controller {
  static targets = ["addressSection", "businessSection", "licenseLabel", "categorySelect"]

  connect() {
    this.toggleRole()
    this.updateLicenseLabel()
  }

  // ロール選択に応じて遺族用・業者用フィールドを切り替える
  toggleRole() {
    const roleSelect = this.element.querySelector("select[name*='role']")
    const role = roleSelect ? roleSelect.value : this._hiddenRole()

    if (this.hasAddressSectionTarget) {
      this.addressSectionTarget.style.display = role === "family" ? "" : "none"
    }
    if (this.hasBusinessSectionTarget) {
      this.businessSectionTarget.style.display = role === "business" ? "" : "none"
    }
  }

  // 業種選択に応じて許可証ラベルを更新する
  updateLicenseLabel() {
    if (!this.hasLicenseLabelTarget) return
    const category = this.hasCategorySelectTarget
      ? this.categorySelectTarget.value
      : null
    this.licenseLabelTarget.textContent =
      LICENSE_LABELS[category] || "許可証・登録番号"
  }

  // hidden フィールドのロール値を取得する
  _hiddenRole() {
    const hidden = this.element.querySelector("input[type='hidden'][name*='role']")
    return hidden ? hidden.value : "family"
  }
}
