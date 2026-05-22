class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]

  def index
    if user_signed_in?
      @recent_items = current_user.items.order(created_at: :desc).limit(5)
      @pending_todos = current_user.todo_items.incomplete.by_priority.limit(5)
      @recent_memories = current_user.memories.order(created_at: :desc).limit(3)
    end
  end
end
