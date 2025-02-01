class AddFileUploadIdToEligibleEyProviders < ActiveRecord::Migration[8.0]
  def up
    add_reference :eligible_ey_providers, :file_upload, type: :uuid, foreign_key: true, null: true

    remove_index :eligible_ey_providers, :urn
    add_index :eligible_ey_providers, [:urn, :file_upload_id], unique: true

    FileUpload.reset_column_information
    EligibleEyProvider.reset_column_information

    file_upload = FileUpload.create!(
      target_data_model: EligibleEyProvider.to_s,
      completed_processing_at: Time.zone.now
    )

    EligibleEyProvider
      .unscoped
      .update_all(file_upload_id: file_upload.id)
  end

  def down
    remove_index :eligible_ey_providers, [:urn, :file_upload_id], unique: true
    remove_reference :eligible_ey_providers, :file_upload

    add_index :eligible_ey_providers, :urn
  end
end
