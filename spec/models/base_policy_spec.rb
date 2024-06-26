require "rails_helper"

module Policies
  module TestPolicyA
    include BasePolicy

    extend self

    class Eligibility
    end
  end

  module TestPolicyB
    include BasePolicy

    extend self

    class Eligibility
    end
  end

  module TestPolicy
    include BasePolicy

    extend self

    OTHER_CLAIMABLE_POLICIES = [
      TestPolicyA,
      TestPolicyB
    ].freeze

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["some_reference"]].freeze

    class Eligibility
    end
  end
end

RSpec.describe BasePolicy, type: :model do
  describe "::to_s" do
    it do
      expect(Policies::TestPolicy.to_s).to eq("TestPolicy")
    end
  end

  describe "::policy_type" do
    it do
      expect(Policies::TestPolicy.policy_type).to eq("test-policy")
    end
  end

  describe "::short_name" do
    before do
      allow(I18n).to receive(:t)
    end

    it do
      Policies::TestPolicy.short_name

      expect(I18n).to have_received(:t).with("test_policy.policy_short_name")
    end
  end

  describe "::locale_key" do
    it do
      expect(Policies::TestPolicy.locale_key).to eq("test_policy")
    end
  end

  describe "::policies_claimable" do
    it do
      expect(Policies::TestPolicy.policies_claimable).to contain_exactly(
        Policies::TestPolicy, Policies::TestPolicyA, Policies::TestPolicyB
      )
    end

    it do
      expect(Policies::TestPolicyA.policies_claimable).to be_empty
    end
  end

  describe "::policy_eligibilities_claimable" do
    it do
      expect(Policies::TestPolicy.policy_eligibilities_claimable).to contain_exactly(
        Policies::TestPolicy::Eligibility, Policies::TestPolicyA::Eligibility, Policies::TestPolicyB::Eligibility
      )
    end

    it do
      expect(Policies::TestPolicyA.policy_eligibilities_claimable).to be_empty
    end
  end

  describe "::eligibility_matching_attributes" do
    it do
      expect(Policies::TestPolicy.eligibility_matching_attributes).to contain_exactly(["some_reference"])
    end

    it do
      expect(Policies::TestPolicyA.eligibility_matching_attributes).to be_empty
    end
  end
end
