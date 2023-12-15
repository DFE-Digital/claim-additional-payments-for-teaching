class AddClaimSchoolSomewhereElseToEligibility < ActiveRecord::Migration[7.0]
  def change
    add_column :student_loans_eligibilities, :claim_school_somewhere_else, :boolean, default: nil
  end
end
