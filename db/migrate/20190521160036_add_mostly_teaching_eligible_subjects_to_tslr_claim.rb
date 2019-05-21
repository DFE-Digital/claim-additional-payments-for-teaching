class AddMostlyTeachingEligibleSubjectsToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :mostly_teaching_eligible_subjects, :boolean
  end
end
