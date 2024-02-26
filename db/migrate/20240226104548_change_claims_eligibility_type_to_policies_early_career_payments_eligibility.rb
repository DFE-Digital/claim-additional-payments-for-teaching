class ChangeClaimsEligibilityTypeToPoliciesEarlyCareerPaymentsEligibility < ActiveRecord::Migration[7.0]
  class Claim < ApplicationRecord; end

  def change
    reversible do |dir|
      dir.up do
        Claim.where(eligibility_type: "EarlyCareerPayments::Eligibility").find_each do |claim|
          claim.update!(eligibility_type: "Policies::EarlyCareerPayments::Eligibility")
        end
      end

      dir.down do
        Claim.where(eligibility_type: "Policies::EarlyCareerPayments::Eligibility").find_each do |claim|
          claim.update!(eligibility_type: "EarlyCareerPayments::Eligibility")
        end
      end
    end
  end
end
