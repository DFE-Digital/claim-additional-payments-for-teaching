module Policies
  module DataRetention
    class PoliciesJob < ApplicationJob
      def perform
        Policies.all.each do |policy|
          # Remove this guard once we have data retention set up for all polcies
          next unless policy == Policies::TargetedRetentionIncentivePayments

          policy::DataRetention::Policy.claims_to_scrub.find_each do |claim|
            Policies::DataRetention::ApplyPolicyJob.perform_later(claim)
          end
        end
      end

      def priority
        10
      end
    end
  end
end
