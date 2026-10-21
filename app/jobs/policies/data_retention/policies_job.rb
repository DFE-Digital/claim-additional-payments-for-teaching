module Policies
  module DataRetention
    class PoliciesJob < ApplicationJob
      def perform
        return unless FeatureFlag.enabled?(:apply_data_retention_policy)

        Policies.all.each do |policy|
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
