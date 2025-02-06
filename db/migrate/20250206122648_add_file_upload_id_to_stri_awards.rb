class AddFileUploadIdToStriAwards < ActiveRecord::Migration[8.0]
  def up
    add_reference :levelling_up_premium_payments_awards, :file_upload, type: :uuid, foreign_key: true, null: true

    remove_index :levelling_up_premium_payments_awards, [:academic_year, :school_urn]
    add_index :levelling_up_premium_payments_awards, [:academic_year, :school_urn, :file_upload_id], unique: true

    FileUpload.reset_column_information
    Policies::LevellingUpPremiumPayments::Award.reset_column_information

    academic_years = Policies::LevellingUpPremiumPayments::Award
      .select(:academic_year)
      .distinct(:academic_year)
      .order(:academic_year)
      .pluck(:academic_year)

    academic_years.each do |academic_year|
      file_upload = FileUpload.create!(
        target_data_model: Policies::LevellingUpPremiumPayments::Award.to_s,
        academic_year: academic_year.to_s,
        completed_processing_at: Time.zone.now
      )

      Policies::LevellingUpPremiumPayments::Award
        .unscoped
        .where(academic_year: academic_year.to_s)
        .update_all(file_upload_id: file_upload.id)
    end
  end

  def down
    remove_index :levelling_up_premium_payments_awards, [:academic_year, :school_urn, :file_upload_id], unique: true
    add_index :levelling_up_premium_payments_awards, [:academic_year, :school_urn], name: "lupp_award_by_year_and_urn"

    remove_reference :levelling_up_premium_payments_awards, :file_upload
  end
end
