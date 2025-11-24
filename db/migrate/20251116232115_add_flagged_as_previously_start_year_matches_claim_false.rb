class AddFlaggedAsPreviouslyStartYearMatchesClaimFalse < ActiveRecord::Migration[8.1]
  def change
    add_column :further_education_payments_eligibilities,
      :flagged_as_previously_start_year_matches_claim_false,
      :boolean,
      default: false
  end
end
