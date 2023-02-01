class AddHmrcBankValidationSucceededToClaims < ActiveRecord::Migration[6.1]
  def change
    add_column :claims, :hmrc_bank_validation_succeeded, :boolean, default: false
  end
end
