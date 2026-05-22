class GuestAssessmentSession < ApplicationRecord
  validates :token, presence: true, uniqueness: true

  def self.find_or_create_for(token)
    find_or_create_by!(token: token)
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

  def add_items(count)
    increment!(:assessed_count, count)
  end
end
