class FileUpload < ApplicationRecord
  belongs_to :uploaded_by, class_name: "DfeSignIn::User", optional: true

  scope :by_target_data_model, ->(target_data_model) { where(target_data_model: target_data_model.to_s) }
  scope :by_academic_year, ->(academic_year) { where(academic_year: academic_year&.to_s) }
  scope :completed_processing, -> { where.not(completed_processing_at: nil) }

  scope :latest_version_for, ->(target_data_model, academic_year = nil) {
    by_target_data_model(target_data_model)
      .by_academic_year(academic_year)
      .completed_processing
      .order(created_at: :desc)
      .limit(1)
  }

  def completed_processing!
    update!(completed_processing_at: Time.zone.now)
  end
end
