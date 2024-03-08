class ChangeStudentLoansEligibilityTypeToPoliciesStudentLoans < ActiveRecord::Migration[7.0]
  class Claim < ApplicationRecord; end

  def change
    reversible do |dir|
      dir.up do
        Claim.where(eligibility_type: "StudentLoans::Eligibility").update_all(eligibility_type: "Policies::StudentLoans::Eligibility")
      end

      dir.down do
        Claim.where(eligibility_type: "Policies::StudentLoans::Eligibility").update_all(eligibility_type: "StudentLoans::Eligibility")
      end
    end
  end
end
