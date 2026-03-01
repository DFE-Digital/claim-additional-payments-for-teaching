require "rails_helper"

RSpec.describe "All policies have a data retention policy for all attributes" do
  Policies.all.each do |policy|
    describe "#{policy} data retention policy" do
      it "has a data retention policy for all attributes" do
        skip unless policy == Policies::TargetedRetentionIncentivePayments

        expect(
          Object.const_defined?("Policies::#{policy}::DataRetention::Policy")
        ).to be(true), <<~TEXT
          Policies::#{policy} does not have a data retention policy
          Create a new `Policies::#{policy}::DataRetention::Policy`
          class.
        TEXT

        data_retention_policy = policy::DataRetention::Policy

        Claim.column_names.each do |name|
          expect(
            data_retention_policy.claim_attributes.keys
          ).to include(name.to_sym), <<~TEXT
            Expected Policies::#{policy}::DataRetention::Policy to define a
            retention period for Claim attribute #{name}.
            Update Policies::#{policy}::DataRetention::Policy.claim_attributes
            with a retention period for #{name}.
          TEXT
        end

        policy::Eligibility.column_names.each do |name|
          expect(
            data_retention_policy.eligibility_attributes.keys
          ).to include(name.to_sym), <<~TEXT
            Expected Policies::#{policy}::DataRetention::Policy to define a
            retention period for Eligibility attribute #{name}.
            Update
            Policies::#{policy}::DataRetention::Policy.eligibility_attributes
            with a retention period for #{name}.
          TEXT
        end
      end
    end
  end
end
