class GuestAssessmentSession < ApplicationRecord
  validates :token, presence: true, uniqueness: true

  # INSERT優先で同時リクエスト時の重複作成を防ぐ
  def self.find_or_create_for(token)
    create_or_find_by!(token: token)
  end

  def limit
    AppSetting.guest_assessment_limit
  end

  def remaining
    [ limit - assessed_count, 0 ].max
  end

  def limit_reached?
    assessed_count >= limit
  end

  # limitチェックと加算をロック内でアトミックに実行し、同時リクエストによる超過を防ぐ
  def add_items(count)
    with_lock do
      raise ActiveRecord::Rollback if assessed_count + count > limit
      increment!(:assessed_count, count)
    end
  end
end
