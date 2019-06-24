class AddEligibleSubjectsToTslrClaims < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :eligible_subjects, :integer, array: true, null: false, default: []
  end
end
