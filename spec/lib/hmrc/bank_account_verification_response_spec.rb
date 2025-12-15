require "rails_helper"

RSpec.describe Hmrc::BankAccountVerificationResponse do
  let(:payload) do
    double(
      status: "200",
      body: {
        "sortCodeIsPresentOnEISCD" => sort_code_present_response,
        "nameMatches" => name_matches_response,
        "accountExists" => account_exists_response
      }.to_json
    )
  end
  let(:name_matches_response) { "indeterminate" }
  let(:account_exists_response) { "indeterminate" }
  let(:sort_code_present_response) { "yes" }

  subject(:response) { described_class.new(payload) }

  describe "#name_match?" do
    context "with yes response" do
      let(:name_matches_response) { "yes" }
      it { is_expected.to be_name_match }
    end

    context "with no response" do
      let(:name_matches_response) { "no" }
      it { is_expected.not_to be_name_match }
    end

    context "with partial response" do
      let(:name_matches_response) { "partial" }
      it { is_expected.to be_name_match }
    end

    context "with indeterminate response" do
      let(:name_matches_response) { "indeterminate" }
      it { is_expected.not_to be_name_match }
    end

    context "with inapplicable response" do
      let(:name_matches_response) { "inapplicable" }
      it { is_expected.not_to be_name_match }
    end

    context "with error response" do
      let(:name_matches_response) { "error" }
      it { is_expected.not_to be_name_match }
    end
  end

  describe "#sort_code_correct?" do
    context "with yes response" do
      let(:sort_code_present_response) { "yes" }
      it { is_expected.to be_sort_code_correct }
    end

    context "with no response" do
      let(:sort_code_present_response) { "no" }
      it { is_expected.not_to be_sort_code_correct }
    end

    context "with error response" do
      let(:sort_code_present_response) { "error" }
      it { is_expected.not_to be_sort_code_correct }
    end
  end

  describe "#account_exists?" do
    context "with yes response" do
      let(:account_exists_response) { "yes" }
      it { is_expected.to be_account_exists }
    end

    context "with no response" do
      let(:account_exists_response) { "no" }
      it { is_expected.not_to be_account_exists }
    end

    context "with indeterminate response" do
      let(:account_exists_response) { "indeterminate" }
      it { is_expected.not_to be_account_exists }
    end

    context "with inapplicable response" do
      let(:account_exists_response) { "inapplicable" }
      it { is_expected.not_to be_account_exists }
    end

    context "with error response" do
      let(:account_exists_response) { "error" }
      it { is_expected.not_to be_account_exists }
    end
  end

  describe "#success?" do
    context "when there are no errors" do
      let(:name_matches_response) { "yes" }
      let(:sort_code_present_response) { "yes" }
      let(:account_exists_response) { "yes" }

      it { is_expected.to be_success }
    end

    context "when there are errors" do
      let(:account_exists_response) { "no" }

      it { is_expected.not_to be_success }
    end
  end

  describe "#code" do
    it "returns an int" do
      expect(subject.code).to eql 200
    end
  end
end
