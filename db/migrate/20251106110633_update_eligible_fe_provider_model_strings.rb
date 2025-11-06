class UpdateEligibleFeProviderModelStrings < ActiveRecord::Migration[8.1]
  def up
    FileUpload.where(
      target_data_model: "EligibleFeProvider"
    ).update_all(
      target_data_model: "Policies::FurtherEducationPayments::EligibleFeProvider"
    )
  end

  def down
    FileUpload.where(
      target_data_model: "Policies::FurtherEducationPayments::EligibleFeProvider"
    ).update_all(
      target_data_model: "EligibleFeProvider"
    )
  end
end
