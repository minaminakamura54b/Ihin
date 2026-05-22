import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["progressSection", "progressBar", "progressText", "itemsGrid"]
  static values = { url: String, status: String }

  connect() {
    if (this.statusValue === "pending" || this.statusValue === "processing") {
      this.requestNotificationPermission()
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.pollInterval = setInterval(() => this.poll(), 2000)
  }

  stopPolling() {
    if (this.pollInterval) clearInterval(this.pollInterval)
  }

  async poll() {
    try {
      const res = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      const data = await res.json()
      this.updateProgress(data)

      if (data.status === "completed" || data.status === "failed") {
        this.stopPolling()
        window.location.reload()
        if (data.status === "completed") this.showNotification()
      }
    } catch (e) {
      // ネットワークエラーは無視してポーリング継続
    }
  }

  updateProgress(data) {
    if (this.hasProgressBarTarget && data.total > 0) {
      const pct = Math.round((data.completed / data.total) * 100)
      this.progressBarTarget.style.width = `${pct}%`
    }
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = `${data.completed}/${data.total}点完了`
    }
  }

  requestNotificationPermission() {
    if ("Notification" in window && Notification.permission === "default") {
      Notification.requestPermission()
    }
  }

  showNotification() {
    if ("Notification" in window && Notification.permission === "granted") {
      new Notification("査定が完了しました！", {
        body: "すべての遺品の査定が完了しました。",
        icon: "/icon.png"
      })
    }
  }
}
