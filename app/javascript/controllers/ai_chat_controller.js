import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "form", "submit", "history"]

  connect() {
    this.history = []
    this.scrollToBottom()
  }

  suggest(event) {
    const question = event.currentTarget.dataset.question
    this.inputTarget.value = question
    this.inputTarget.focus()
  }

  keydown(event) {
    // Ctrl+Enter または Cmd+Enter で送信
    if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
  }

  submit(event) {
    event.preventDefault()
    const message = this.inputTarget.value.trim()
    if (!message) return

    // 送信ボタン無効化
    this.submitTarget.disabled = true

    // ローディング表示を追加
    this.appendLoading(message)

    // フォームデータ構築
    const formData = new FormData(this.formTarget)
    formData.set("history", JSON.stringify(this.history))

    // 入力欄クリア
    this.inputTarget.value = ""

    fetch(this.formTarget.action, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: formData
    })
    .then(response => response.text())
    .then(html => {
      // ローディング削除
      this.removeLoading()

      // Turbo Streamで更新
      Turbo.renderStreamMessage(html)

      // 少し待ってから履歴を更新（DOMの更新後）
      setTimeout(() => {
        this.updateHistory(message)
        this.scrollToBottom()
        this.submitTarget.disabled = false
      }, 100)
    })
    .catch(() => {
      this.removeLoading()
      this.submitTarget.disabled = false
    })
  }

  appendLoading(userMessage) {
    const loadingHtml = `
      <div class="chat-turn" id="chat_loading">
        <div class="chat-message-user">
          <div class="chat-bubble chat-bubble-user"><p>${this.escapeHtml(userMessage)}</p></div>
          <div class="chat-avatar chat-avatar-user"><i class="fas fa-user"></i></div>
        </div>
        <div class="chat-message-ai">
          <div class="chat-avatar chat-avatar-ai">🤖</div>
          <div class="chat-bubble chat-bubble-ai chat-loading">
            <span></span><span></span><span></span>
          </div>
        </div>
      </div>`
    this.messagesTarget.insertAdjacentHTML("beforeend", loadingHtml)
    this.scrollToBottom()
  }

  removeLoading() {
    document.getElementById("chat_loading")?.remove()
  }

  updateHistory(userMessage) {
    const turns = this.messagesTarget.querySelectorAll(".chat-turn[data-ai-message]")
    const lastTurn = turns[turns.length - 1]
    if (lastTurn) {
      this.history.push({ role: "user", content: lastTurn.dataset.userMessage })
      this.history.push({ role: "assistant", content: lastTurn.dataset.aiMessage })
      // 履歴は直近6往復まで保持
      if (this.history.length > 12) this.history = this.history.slice(-12)
    }
  }

  scrollToBottom() {
    setTimeout(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }, 50)
  }

  escapeHtml(text) {
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }
}
