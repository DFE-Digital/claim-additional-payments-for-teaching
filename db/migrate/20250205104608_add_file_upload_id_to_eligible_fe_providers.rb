class AddFileUploadIdToEligibleFeProviders < ActiveRecord::Migration[8.0]
  def up
    add_reference :eligible_fe_providers, :file_upload, type: :uuid, foreign_key: true, null: true

    remove_index :eligible_fe_providers, [:academic_year, :ukprn], unique: true
    add_index :eligible_fe_providers, [:academic_year, :ukprn, :file_upload_id], unique: true

    FileUpload.reset_column_information
    EligibleFeProvider.reset_column_information

    academic_years = EligibleFeProvider
      .select(:academic_year)
      .distinct(:academic_year)
      .order(:academic_year)
      .pluck(:academic_year)

    academic_years.each do |academic_year|
      file_upload = FileUpload.create!(
        target_data_model: EligibleFeProvider.to_s,
        academic_year: academic_year.to_s,
        completed_processing_at: Time.zone.now
      )

      EligibleFeProvider
        .unscoped
        .where(academic_year: academic_year.to_s)
        .update_all(file_upload_id: file_upload.id)
    end
  end

  def down
    remove_index :eligible_fe_providers, [:academic_year, :ukprn, :file_upload_id], unique: true
    add_index :eligible_fe_providers, [:academic_year, :ukprn], unique: true

    remove_reference :eligible_fe_providers, :file_upload
  end
end
