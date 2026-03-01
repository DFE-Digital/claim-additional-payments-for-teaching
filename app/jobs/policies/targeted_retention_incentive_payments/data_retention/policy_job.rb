module Policies
  module TargetedRetentionIncentivePayments
    module DataRetention
      class PolicyJob < ApplicationJob
        def perform
          # TODO use scopes returning claims that likely need scrubbing
          Claim.by_policy(Policies::TargetedRetentionIncentivePayments).all.each do |claim|
            Policies::DataRetention::ApplyPolicyJob.perform_later(claim)
          end
        end
      end
    end
  end
end
