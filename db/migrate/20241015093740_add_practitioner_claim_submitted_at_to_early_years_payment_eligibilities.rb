class AddPractitionerClaimSubmittedAtToEarlyYearsPaymentEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :early_years_payment_eligibilities, :practitioner_claim_submitted_at, :datetime
  end
end
