class AlbumsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :shared ]
  before_action :set_album,          only: [ :show, :edit, :update, :destroy, :add_memories, :upload_photo, :remove_memory, :generate_ai_summary, :toggle_share ]
  before_action :set_album_by_token, only: [ :shared ]

  def index
    @albums = current_user.albums.ordered.includes(:memories)
  end

  def show
    @memories = @album.memories.includes(:item).order("album_memories.position ASC, memories.created_at DESC")
    # アルバムに未追加の思い出（追加候補として使う）
    @other_memories = current_user.memories
                                  .where.not(id: @album.memory_ids)
                                  .includes(:item)
                                  .order(created_at: :desc)
  end

  def new
    @album = current_user.albums.new
  end

  def create
    @album = current_user.albums.new(album_params)
    if @album.save
      redirect_to @album, notice: "アルバムを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @album.update(album_params)
      redirect_to @album, notice: "アルバムを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @album.destroy
    redirect_to albums_path, notice: "アルバムを削除しました"
  end

  # 写真を直接アルバムにアップロード（複数可・Memory を自動生成して紐付け）
  def upload_photo
    photos = Array(params[:photos]).select { |p| p.respond_to?(:content_type) }

    if photos.empty?
      redirect_to @album, alert: "写真を選択してください" and return
    end

    saved_memories = []
    errors = []

    photos.each do |photo|
      # 画像種別・サイズのバリデーション
      unless photo.content_type.start_with?("image/")
        errors << "#{photo.original_filename}：画像ファイルではありません"
        next
      end
      if photo.size > 20.megabytes
        errors << "#{photo.original_filename}：20MB以内にしてください"
        next
      end

      memory = current_user.memories.new(photo: photo)
      if memory.save
        AlbumMemory.create!(album: @album, memory: memory)
        saved_memories << memory
      else
        errors << "#{photo.original_filename}：#{memory.errors.full_messages.to_sentence}"
      end
    end

    notice = saved_memories.any? ? "#{saved_memories.size}枚の写真を追加しました" : nil
    alert  = errors.any? ? errors.join(" / ") : nil

    redirect_to @album, notice: notice, alert: alert
  end

  # 選択した思い出をまとめてアルバムに追加
  def add_memories
    memory_ids = params[:memory_ids].to_a.map(&:to_i)
    added = 0
    memory_ids.each do |mid|
      memory = current_user.memories.find_by(id: mid)
      next unless memory
      # すでに追加済みはスキップ（create_or_find_by で重複防止）
      am = AlbumMemory.create_or_find_by(album: @album, memory: memory)
      am.update(position: @album.album_memories.count) if am.persisted? && am.position == 0
      added += 1
    end

    redirect_to @album, notice: "#{added}件の思い出を追加しました"
  end

  # アルバムから思い出を1件削除
  def remove_memory
    memory = current_user.memories.find(params[:memory_id])
    @album.album_memories.find_by(memory: memory)&.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("album_memory_#{memory.id}")
      end
      format.html { redirect_to @album, notice: "削除しました" }
    end
  end

  # AIが追悼文を生成
  def generate_ai_summary
    memories = @album.memories.order(created_at: :desc).limit(20)
    if memories.empty?
      redirect_to @album, alert: "アルバムに思い出を追加してからAI追悼文を生成してください" and return
    end

    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])

    episodes = memories.map { |m|
      parts = [ m.title, m.description, m.comment ].compact.join("　")
      parts.present? ? "・#{parts}" : nil
    }.compact.join("\n")

    prompt = <<~PROMPT
      以下のアルバム「#{@album.title}」に記録された思い出をもとに、
      温かく美しい追悼文を生成してください。
      遺族の気持ちに寄り添った300〜400文字の文章にしてください。
      文章は日本語で書いてください。

      思い出の記録：
      #{episodes}
    PROMPT

    response = client.messages.create(
      model:      "claude-sonnet-4-5",
      max_tokens: 1024,
      messages:   [ { role: "user", content: prompt } ]
    )

    @album.update!(ai_summary: response.content.first.text.strip)
    redirect_to @album, notice: "AI追悼文を生成しました"
  rescue => e
    redirect_to @album, alert: "AI追悼文の生成に失敗しました。もう一度お試しください。"
  end

  # 共有のON/OFF切り替え
  def toggle_share
    @album.update!(shared: !@album.shared)
    redirect_to @album, notice: @album.shared? ? "共有URLを発行しました" : "共有を停止しました"
  end

  # ログイン不要の公開アルバムページ
  def shared
    @memories = @shared_album.memories.where(shared: true)
                             .order("album_memories.position ASC")
    render :shared, layout: "memorial"
  end

  private

  def set_album
    @album = current_user.albums.find(params[:id])
  end

  def set_album_by_token
    @shared_album = Album.find_by!(share_token: params[:token], shared: true)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "このアルバムは存在しないか、共有が停止されています"
  end

  def album_params
    params.require(:album).permit(:title, :description, :cover_image)
  end
end
