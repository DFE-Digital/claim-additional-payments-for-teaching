module Policies
  module DataRetention
    class ApplyPolicyJob < ApplicationJob
      def perform(claim)
        change_set = claim.policy::DataRetention::Policy.apply(claim)
        return unless change_set.any_changes?

        expired_eligibility_attachments = change_set.expired_eligibility_attachments

        ApplicationRecord.transaction do
          claim.journey_session&.update!(answers: {})

          backup_claim!(claim)

          claim.update!(change_set.new_claim_attributes)
          claim.eligibility.update!(change_set.new_eligibility_attributes)

          claim.amendments.each do |amendment|
            amendment.update!(change_set.new_amendment_attributes(amendment))
          end
        end

        expired_eligibility_attachments.each(&:purge)
      end

      def priority
        10
      end

      private

      def backup_claim!(claim)
        Policies::DataRetention::Recovery.create!(
          claim: claim,
          destroy_at: 1.week.from_now,
          payload: {
            claim_attributes: claim.attributes,
            eligibility_attributes: claim.eligibility.attributes,
            amendments_attributes: claim.amendments.map(&:attributes)
          }
        )
      end
    end
  end
end
