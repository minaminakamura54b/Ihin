class MemoriesController < ApplicationController
  before_action :set_memory, only: [ :show, :edit, :update, :destroy ]

  def index
    @memories = current_user.memories.includes(:item).order(created_at: :desc).page(params[:page]).per(12)
  end

  def show
  end

  def new
    @memory = current_user.memories.new
    @memory.item_id = params[:item_id]
  end

  def create
    @memory = current_user.memories.new(memory_params)
    if @memory.save
      redirect_to memories_path, notice: "思い出を保存しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @memory.update(memory_params)
      redirect_to @memory, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @memory.destroy
    redirect_to memories_path, notice: "削除しました"
  end

  private

  def set_memory
    @memory = current_user.memories.find(params[:id])
  end

  def memory_params
    params.require(:memory).permit(:item_id, :comment, :photo)
  end
end
