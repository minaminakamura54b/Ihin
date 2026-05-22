class AiConsultationsController < ApplicationController
  def show
    @past_consultations = current_user.consultations.recent.limit(20).reverse
    @suggested_questions = [
      "遺品整理はどこから始めればいいですか？",
      "銀行口座の相続手続きの流れを教えてください",
      "デジタル遺品（SNS・サブスク）の整理方法は？",
      "相続放棄とはどういうものですか？",
      "遺品を売る場合、どんな業者に頼めばいいですか？",
      "四十九日までにやるべきことを教えてください",
      "故人のスマートフォンのデータはどう扱えばいいですか？",
      "遺品整理業者を選ぶときのポイントは？",
    ]
  end
end
