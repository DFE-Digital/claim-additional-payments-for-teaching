class FixFileUploadsEyTargetDataModel < ActiveRecord::Migration[8.1]
  def up
    FileUpload.where(
      target_data_model: "Policies::FurtherEducationPayments::EligibleEyProvider"
    ).update_all(
      target_data_model: "Policies::EarlyYearsPayments::EligibleEyProvider"
    )
  end

  def down
    FileUpload.where(
      target_data_model: "Policies::EarlyYearsPayments::EligibleEyProvider"
    ).update_all(
      target_data_model: "Policies::FurtherEducationPayments::EligibleEyProvider"
    )
  end
end
