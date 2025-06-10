class AddPerviousYearClaimsToIrpEligibility < ActiveRecord::Migration[8.0]
  def change
    add_column(
      :international_relocation_payments_eligibilities,
      :previous_year_claim_ids,
      :text,
      array: true,
      default: []
    )
  end
end
