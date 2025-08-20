class AddAlternativeIdvReferenceToEyEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :early_years_payment_eligibilities,
      :alternative_idv_reference,
      :string
    )

    add_index(
      :early_years_payment_eligibilities,
      :alternative_idv_reference,
      unique: true
    )
  end
end
