ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    # fixtures :all を削除 — FactoryBot に完全移行
    # factory_bot_rails が自動ロードするため find_definitions は不要
    include FactoryBot::Syntax::Methods
  end
end

# コントローラー・統合テストで sign_in/sign_out が使えるように
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
