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

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["some_reference"]].freeze

    SEARCHABLE_ELIGIBILITY_ATTRIBUTES = %w[some_searchable_reference].freeze

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

  describe "::eligibility_matching_attributes" do
    it do
      expect(Policies::TestPolicy.eligibility_matching_attributes).to contain_exactly(["some_reference"])
    end

    it do
      expect(Policies::TestPolicyA.eligibility_matching_attributes).to be_empty
    end
  end

  describe "::searchable_eligibility_attributes" do
    it do
      expect(Policies::TestPolicy.searchable_eligibility_attributes).to contain_exactly("some_searchable_reference")
    end

    it do
      expect(Policies::TestPolicyA.searchable_eligibility_attributes).to be_empty
    end
  end

  describe "#decision_deadline_date" do
    let(:claim) { build(:claim, :submitted) }

    it "is 19 weeks after submitted date" do
      expect(Policies::TestPolicy.decision_deadline_date(claim)).to eql((claim.submitted_at + 19.weeks).to_date)
    end
  end

  describe "#award_amount_rules" do
    it "is nil for a policy that does not constrain award size" do
      expect(Policies::TestPolicy.award_amount_rules(build(:claim))).to be_nil
    end

    # Guards the dispatch in each eligibility, which deliberately does not use safe
    # navigation: if one of these overrides is dropped, award validation stops
    # running entirely.
    {
      Policies::StudentLoans => Policies::StudentLoans::AwardAmountRules,
      Policies::TargetedRetentionIncentivePayments =>
        Policies::TargetedRetentionIncentivePayments::AwardAmountRules
    }.each do |policy, rules_class|
      it "returns #{rules_class} for #{policy}" do
        record = build(:"#{policy.to_s.underscore}_eligibility")

        expect(policy.award_amount_rules(record)).to be_a(rules_class)
      end
    end
  end
end
