class AddClaimantDetailsToEyEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :early_years_payment_eligibilities, :practitioner_first_name, :string
    add_column :early_years_payment_eligibilities, :practitioner_surname, :string
  end
end
