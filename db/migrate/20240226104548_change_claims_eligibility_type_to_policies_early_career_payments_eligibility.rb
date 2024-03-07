class ChangeClaimsEligibilityTypeToPoliciesEarlyCareerPaymentsEligibility < ActiveRecord::Migration[7.0]
  class Claim < ApplicationRecord; end

  def change
    reversible do |dir|
      dir.up do
        Claim.where(eligibility_type: "EarlyCareerPayments::Eligibility").update_all(eligibility_type: "Policies::EarlyCareerPayments::Eligibility")
      end

      dir.down do
        Claim.where(eligibility_type: "Policies::EarlyCareerPayments::Eligibility").update_all(eligibility_type: "EarlyCareerPayments::Eligibility")
      end
    end
  end
end
