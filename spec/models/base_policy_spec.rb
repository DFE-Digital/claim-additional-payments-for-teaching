require "rails_helper"

module Policies
  module TestPolicyA
    include BasePolicy

    APPROVED_MIN_QA_THRESHOLD = 7
    REJECTED_MIN_QA_THRESHOLD = 13

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

  describe "::decision_deadline_date" do
    let(:claim) { build(:claim, :submitted) }

    it "is 19 weeks after submitted date" do
      expect(Policies::TestPolicy.decision_deadline_date(claim)).to eql((claim.submitted_at + 19.weeks).to_date)
    end
  end

  describe "::approved_min_qa_threshold" do
    context "when journey not present" do
      it "returns constant" do
        expect(Policies::TestPolicyA.approved_min_qa_threshold).to eql(7)
      end
    end

    context "when journey present but no journey configuration" do
      let(:mock_journey) do
        Journeys::FurtherEducationPayments
      end

      before do
        allow(Journeys).to receive(:for_policy).and_return(mock_journey)
      end

      it "returns constant" do
        expect(Policies::TestPolicyA.approved_min_qa_threshold).to eql(7)
      end
    end

    context "when journey present with journey configuration with nil value" do
      let(:mock_journey) do
        Journeys::FurtherEducationPayments
      end

      let(:mock_journey_configuration) do
        build(
          :journey_configuration,
          approved_min_qa_threshold: nil
        )
      end

      before do
        allow(Journeys).to receive(:for_policy).and_return(mock_journey)
        allow(Journeys::Configuration).to receive(:find_by).and_return(mock_journey_configuration)
      end

      it "returns constant" do
        expect(Policies::TestPolicyA.approved_min_qa_threshold).to eql(7)
      end
    end

    context "when journey present and configured" do
      let(:mock_journey) do
        Journeys::FurtherEducationPayments
      end

      let(:mock_journey_configuration) do
        build(
          :journey_configuration,
          approved_min_qa_threshold: 14
        )
      end

      before do
        allow(Journeys).to receive(:for_policy).and_return(mock_journey)
        allow(Journeys::Configuration).to receive(:find_by).and_return(mock_journey_configuration)
      end

      it "returns configured value" do
        expect(Policies::TestPolicyA.approved_min_qa_threshold).to eql(14)
      end
    end
  end

  describe "::rejected_min_qa_threshold" do
    context "when journey not present" do
      it "returns constant" do
        expect(Policies::TestPolicyA.rejected_min_qa_threshold).to eql(13)
      end
    end

    context "when journey present but no journey configuration" do
      let(:mock_journey) do
        Journeys::FurtherEducationPayments
      end

      before do
        allow(Journeys).to receive(:for_policy).and_return(mock_journey)
      end

      it "returns constant" do
        expect(Policies::TestPolicyA.rejected_min_qa_threshold).to eql(13)
      end
    end

    context "when journey present with journey configuration with nil value" do
      let(:mock_journey) do
        Journeys::FurtherEducationPayments
      end

      let(:mock_journey_configuration) do
        build(
          :journey_configuration,
          rejected_min_qa_threshold: nil
        )
      end

      before do
        allow(Journeys).to receive(:for_policy).and_return(mock_journey)
        allow(Journeys::Configuration).to receive(:find_by).and_return(mock_journey_configuration)
      end

      it "returns constant" do
        expect(Policies::TestPolicyA.rejected_min_qa_threshold).to eql(13)
      end
    end

    context "when journey present and configured" do
      let(:mock_journey) do
        Journeys::FurtherEducationPayments
      end

      let(:mock_journey_configuration) do
        build(
          :journey_configuration,
          rejected_min_qa_threshold: 26
        )
      end

      before do
        allow(Journeys).to receive(:for_policy).and_return(mock_journey)
        allow(Journeys::Configuration).to receive(:find_by).and_return(mock_journey_configuration)
      end

      it "returns configured value" do
        expect(Policies::TestPolicyA.rejected_min_qa_threshold).to eql(26)
      end
    end
  end
end
