class UpdateEligibleEyProviderModelStrings < ActiveRecord::Migration[8.1]
  def up
    FileUpload.where(
      target_data_model: "EligibleEyProvider"
    ).update_all(
      target_data_model: "Policies::FurtherEducationPayments::EligibleEyProvider"
    )
  end

  def down
    FileUpload.where(
      target_data_model: "Policies::FurtherEducationPayments::EligibleEyProvider"
    ).update_all(
      target_data_model: "EligibleEyProvider"
    )
  end
end
