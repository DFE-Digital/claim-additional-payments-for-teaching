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

    it "is 13 weeks after submitted date" do
      expect(Policies::TestPolicy.decision_deadline_date(claim)).to eql((claim.submitted_at + 13.weeks).to_date)
    end
  end
end
