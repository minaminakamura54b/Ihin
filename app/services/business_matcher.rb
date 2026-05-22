class BusinessMatcher
  MAX_BUSINESSES = 3

  def self.find_for(user, category: nil)
    businesses = Business.active.where.not(area: [nil, ""])

    # エリアでフィルタリング
    if user&.prefecture.present?
      businesses = businesses.where(
        "area LIKE ?", "%#{user.prefecture}%"
      )
    end

    # カテゴリでフィルタリング
    if category.present?
      businesses = businesses.where(category: category)
    end

    # プラン順に並べて最大3社
    businesses.order(
      Arel.sql(
        "CASE plan
          WHEN 3 THEN 1
          WHEN 2 THEN 2
          WHEN 1 THEN 3
          WHEN 0 THEN 4
        END"
      )
    ).limit(MAX_BUSINESSES)
  end
end
