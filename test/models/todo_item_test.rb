require "test_helper"

class TodoItemTest < ActiveSupport::TestCase
  # ===== TEMPLATES =====

  test "TEMPLATES は 46件ある" do
    assert_equal 46, TodoItem::TEMPLATES.count
  end

  test "TEMPLATES の全エントリは title / category / priority を持つ" do
    TodoItem::TEMPLATES.each do |t|
      assert t[:title].present?, "title が空のテンプレートがある: #{t.inspect}"
      assert_includes [ :urgent, :normal, :digital ], t[:category],
        "不正な category: #{t[:category]}"
      assert t[:priority].present?, "priority がないテンプレートがある: #{t.inspect}"
    end
  end

  # ===== バリデーション =====

  test "title がない場合は無効" do
    todo = TodoItem.new(user: create(:user), title: "", category: :normal)
    assert_not todo.valid?
  end

  test "user なしでは無効" do
    todo = TodoItem.new(title: "タスク", category: :normal)
    assert_not todo.valid?
  end

  # ===== scope =====

  test "by_priority scope は priority 昇順で返す" do
    # admin ユーザーは auto-generate のコールバックがないため TodoItem が増えない
    user = create(:user, :admin)
    t3 = create(:todo_item, user: user, priority: 3)
    t1 = create(:todo_item, user: user, priority: 1)
    t2 = create(:todo_item, user: user, priority: 2)
    assert_equal [ t1, t2, t3 ], user.todo_items.by_priority.to_a
  end

  test "incomplete scope は completed=false のみ返す" do
    user = create(:user)
    done = create(:todo_item, user: user, completed: true)
    todo = create(:todo_item, user: user, completed: false)
    assert_includes TodoItem.incomplete, todo
    assert_not_includes TodoItem.incomplete, done
  end

  test "complete scope は completed=true のみ返す" do
    user = create(:user)
    done = create(:todo_item, user: user, completed: true)
    todo = create(:todo_item, user: user, completed: false)
    assert_includes TodoItem.complete, done
    assert_not_includes TodoItem.complete, todo
  end

  # ===== category_label =====

  test "category_label は urgent で '急ぎ' を返す" do
    item = build(:todo_item, :urgent)
    assert_equal "急ぎ", item.category_label
  end

  test "category_label は normal で '通常' を返す" do
    item = build(:todo_item)
    assert_equal "通常", item.category_label
  end

  test "category_label は digital で 'デジタル遺品' を返す" do
    item = build(:todo_item, :digital)
    assert_equal "デジタル遺品", item.category_label
  end
end
