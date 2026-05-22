class BulkAssessmentJob < ApplicationJob
  queue_as :default

  def perform(bulk_assessment_id)
    bulk = BulkAssessment.find(bulk_assessment_id)
    bulk.update!(status: :processing)

    bulk.bulk_assessment_items.order(:position).each do |item|
      next if item.completed?

      item.update!(status: :processing)
      result = assess_item(item)

      if result[:success]
        safe_action = BulkAssessmentItem::VALID_ACTIONS.include?(result[:suggested_action]) ? result[:suggested_action] : nil
        item.update!(
          status: :completed,
          ai_result: result[:ai_result],
          estimated_price: result[:estimated_price],
          suggested_action: safe_action
        )
      else
        item.update!(status: :failed, error_message: result[:error])
      end
    end

    bulk.update!(status: :completed)
  rescue => e
    BulkAssessment.find_by(id: bulk_assessment_id)&.update(status: :failed)
    raise
  end

  private

  def assess_item(item)
    images = item.photos.map do |photo|
      data = photo.download rescue nil
      next nil unless data
      { data: data, content_type: photo.content_type }
    end.compact

    AiAssessmentService.assess_upload(
      images: images,
      name: item.display_name,
      memo: nil
    )
  end
end
