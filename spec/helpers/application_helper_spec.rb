require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#currency_value_for_number_field" do
    let(:value) { 1000.1 }

    it "formats the number to two decimal places and is suitable for a number_field" do
      expect(helper.currency_value_for_number_field(value)).to eql("1000.10")
    end

    context "when no value exists" do
      let(:value) { nil }

      it "does no formatting and just returns nil" do
        expect(helper.currency_value_for_number_field(value)).to be_nil
      end
    end
  end

  describe "page_title" do
    it "returns a title for the page that follows the guidance of the design system" do
      expected_title = page_title("Title", journey: "student-loans")
      expect(expected_title).to eq("Title — Teachers: claim back your student loan repayments — GOV.UK")
    end

    it "uses the generic service name if a specific policy isn't available" do
      expect(page_title("Some Title", journey: nil)).to eq("Some Title — Claim additional payments for teaching — GOV.UK")
    end

    it "includes an optional error prefix" do
      expected_title = page_title("Some Title", show_error: true, journey: "student-loans")
      expect(expected_title).to eq("Error — Some Title — Teachers: claim back your student loan repayments — GOV.UK")
    end
  end

  describe "#support_email_address" do
    it "defaults to the generic support address" do
      expect(support_email_address).to eq t("support_email_address")
    end

    it "returns a policy-specific email address based on routing path" do
      expect(support_email_address("student-loans")).to eq t("student_loans.support_email_address")
      expect(support_email_address("targeted-retention-incentive-payments")).to eq t("targeted_retention_incentive_payments.support_email_address")
    end
  end

  describe "#journey_service_name" do
    it "defaults to the generic service name" do
      expect(journey_service_name).to eq t("service_name")
    end

    it "returns a policy-specific service name for student loans" do
      expect(journey_service_name("student-loans")).to eq t("student_loans.journey_name")
    end

    it "returns a policy-specific service name for additional payments" do
      expect(journey_service_name("targeted-retention-incentive-payments")).to eq t("targeted_retention_incentive_payments.journey_name")
    end
  end

  describe "#information_provided_further_details_with_link" do
    subject { information_provided_further_details_with_link(policy:) }

    context "policy is a Teacher Student Loan Reimbursement" do
      let(:policy) { Policies::StudentLoans }

      it { is_expected.to eq('For more details, you can read about payments and deductions when <a class="govuk-link govuk-link--no-visited-state" target="_blank" href="https://www.gov.uk/guidance/teachers-claim-back-your-student-loan-repayments#payment">claiming back your student loan repayments (opens in new tab)</a>') }
    end

    context "policy is a TargetedRetentionIncentivePayments" do
      let(:policy) { Policies::TargetedRetentionIncentivePayments }

      it { is_expected.to eq('For more details, you can read about payments and deductions for the <a class="govuk-link govuk-link--no-visited-state" target="_blank" href="https://www.gov.uk/guidance/targeted-retention-incentive-payments-for-school-teachers#payments-and-deductions">school targeted retention incentive (opens in new tab)</a>') }
    end
  end

  describe "#one_login_home_url" do
    context "when ONELOGIN_DID_URL env var not present" do
      it "defaults to production url" do
        stub_const("ENV", {})

        expect(helper.one_login_home_url).to eql("https://home.account.gov.uk/")
      end
    end

    context "when ONELOGIN_DID_URL set to integration value" do
      it "returns integration url" do
        stub_const("ENV", {"ONELOGIN_DID_URL" => "https://identity.integration.account.gov.uk/.well-known/did.json"})

        expect(helper.one_login_home_url).to eql("https://home.integration.account.gov.uk/")
      end
    end

    context "when ONELOGIN_DID_URL set to production value" do
      it "returns production url" do
        stub_const("ENV", {"ONELOGIN_DID_URL" => "https://identity.account.gov.uk/.well-known/did.json"})

        expect(helper.one_login_home_url).to eql("https://home.account.gov.uk/")
      end
    end
  end
end
