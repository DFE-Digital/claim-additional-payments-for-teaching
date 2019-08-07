class RemoveSubjectsTaughtAttributesFromTslrClaims < ActiveRecord::Migration[5.2]
  def change
    change_table :tslr_claims do |t|
      t.remove :biology_taught
      t.remove :chemistry_taught
      t.remove :computer_science_taught
      t.remove :languages_taught
      t.remove :physics_taught
      t.remove :mostly_teaching_eligible_subjects
    end
  end
end
