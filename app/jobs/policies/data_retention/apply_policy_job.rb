module Policies
  module DataRetention
    class ApplyPolicyJob < ApplicationJob
      def perform(claim)
        change_set = claim.policy::DataRetention::Policy.apply(claim)

        ApplicationRecord.transaction do
          # TODO handle scrubbing journey session
          claim.update!(change_set.new_claim_attributes)
          claim.eligibility.update!(change_set.new_eligibility_attributes)

          claim.amendments.each do |amendment|
            amendment.update!(change_set.new_amendment_attributes(amendment))
          end
        end
      end
    end
  end
end
