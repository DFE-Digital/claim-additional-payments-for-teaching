class AddContractTypeToEyEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :early_years_payment_eligibilities,
      :provider_entered_contract_type,
      :string
    )
  end
end
