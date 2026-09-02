require "rails_helper"

RSpec.describe Admin::HmrcBankVerificationPresenter do
  subject(:presenter) { described_class.new(response) }

  let(:response) do
    {
      "code" => code,
      "body" => body
    }
  end

  let(:code) { 200 }

  let(:body) do
    {
      "sortCodeIsPresentOnEISCD" => sort_code_present_on_eiscd,
      "accountExists" => account_exists,
      "nameMatches" => name_matches
    }
  end

  let(:sort_code_present_on_eiscd) { "yes" }
  let(:account_exists) { "yes" }
  let(:name_matches) { "yes" }

  describe "#errored?" do
    context "when the response code is a success" do
      let(:code) { 200 }

      it { is_expected.not_to be_errored }
    end

    context "when the response code is a redirect" do
      let(:code) { 300 }

      it { is_expected.not_to be_errored }
    end

    context "when the response code is an error" do
      let(:code) { 429 }

      it { is_expected.to be_errored }
    end
  end

  describe "#success?" do
    context "when the sort code, account number and name all match" do
      it { is_expected.to be_success }
    end

    context "when the sort code isn't found" do
      let(:sort_code_present_on_eiscd) { "no" }

      it { is_expected.not_to be_success }
    end

    context "when the account number doesn't match" do
      let(:account_exists) { "no" }

      it { is_expected.not_to be_success }
    end

    context "when the name doesn't match" do
      let(:name_matches) { "no" }

      it { is_expected.not_to be_success }
    end

    context "when the name partially matches" do
      let(:name_matches) { "partial" }

      it { is_expected.not_to be_success }
    end

    context "when HMRC didn't return an answer" do
      let(:body) { {} }

      it { is_expected.not_to be_success }
    end

    context "when the request errored" do
      let(:code) { 429 }
      let(:body) { "Test failure" }

      it { is_expected.not_to be_success }
    end
  end

  describe "#title" do
    context "when the details were verified" do
      it "reports success" do
        expect(presenter.title).to eq("Bank details verified with HMRC")
      end
    end

    context "when the details weren't verified" do
      let(:name_matches) { "no" }

      it "reports failure" do
        expect(presenter.title).to eq(
          "Bank details could not be verified with HMRC"
        )
      end
    end
  end

  describe "#rows" do
    context "when the details were verified" do
      it "describes each check" do
        expect(presenter.rows).to eq(
          [
            "Sort code: Yes - sort code found",
            "Account number: Yes - sort code and account number match",
            "Name on the account: Yes - name matches the account holder name"
          ]
        )
      end
    end

    context "when the details weren't verified" do
      let(:sort_code_present_on_eiscd) { "no" }
      let(:account_exists) { "no" }
      let(:name_matches) { "no" }

      it "describes each check" do
        expect(presenter.rows).to eq(
          [
            "Sort code: No - sort code not found",
            "Account number: No - sort code and account number do not match",
            "Name on the account: No - name does not match the account holder name"
          ]
        )
      end
    end

    context "when the name partially matches" do
      let(:name_matches) { "partial" }

      it "describes the partial match" do
        expect(presenter.rows.last).to eq(
          "Name on the account: Partial - name partially matches the account holder name"
        )
      end
    end

    context "when HMRC didn't return an answer" do
      let(:body) { {} }

      it "describes each check as unknown" do
        expect(presenter.rows).to eq(
          [
            "Sort code: Unknown - HMRC did not return an answer",
            "Account number: Unknown - HMRC did not return an answer",
            "Name on the account: Unknown - HMRC did not return an answer"
          ]
        )
      end
    end

    context "when the request errored" do
      let(:code) { 429 }
      let(:body) { "Test failure" }

      it "describes each check as unknown" do
        expect(presenter.rows).to eq(
          [
            "Sort code: Unknown - HMRC did not return an answer",
            "Account number: Unknown - HMRC did not return an answer",
            "Name on the account: Unknown - HMRC did not return an answer"
          ]
        )
      end
    end
  end
end
