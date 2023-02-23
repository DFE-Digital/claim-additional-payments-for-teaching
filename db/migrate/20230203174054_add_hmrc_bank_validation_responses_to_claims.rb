class AddHmrcBankValidationResponsesToClaims < ActiveRecord::Migration[6.1]
  def change
    add_column :claims, :hmrc_bank_validation_responses, :json, default: []
  end
end
