class TodoItemsController < ApplicationController
  before_action :set_todo_item, only: [ :edit, :update, :destroy, :toggle ]

  def index
    @urgent_todos = current_user.todo_items.urgent.by_priority
    @normal_todos = current_user.todo_items.normal.by_priority
    @digital_todos = current_user.todo_items.digital.by_priority
  end

  def new
    @todo_item = current_user.todo_items.new(category: params[:category] || "normal")
  end

  def create
    @todo_item = current_user.todo_items.new(todo_item_params)
    if @todo_item.save
      redirect_to todo_items_path, notice: "タスクを追加しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @todo_item.update(todo_item_params)
      redirect_to todo_items_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @todo_item.destroy
    respond_to do |format|
      format.html { redirect_to todo_items_path }
      format.turbo_stream { render turbo_stream: turbo_stream.remove("todo_item_#{@todo_item.id}") }
    end
  end

  def toggle
    @todo_item.update(completed: !@todo_item.completed)
    respond_to do |format|
      format.html { redirect_to todo_items_path }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("todo_item_#{@todo_item.id}", partial: "todo_items/todo_item", locals: { todo_item: @todo_item }) }
    end
  end

  private

  def set_todo_item
    @todo_item = current_user.todo_items.find(params[:id])
  end

  def todo_item_params
    params.require(:todo_item).permit(:title, :category, :priority, :completed)
  end
end
