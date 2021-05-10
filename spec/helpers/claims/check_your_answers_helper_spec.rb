require "rails_helper"

RSpec.describe Claims::CheckYourAnswersHelper do
  let(:claim) { build(:claim, policy: policy) }

  describe "#send_your_application(claim)" do
    context "with a StudentLoans policy" do
      let(:policy) { StudentLoans }

      it "returns the correct content block" do
        expect(helper.send_your_application(claim)).to include(I18n.t("check_your_answers.heading_send_application"), "h2", "govuk-heading-m")
      end
    end

    context "with a EarlyCareerPayments policy" do
      let(:policy) { EarlyCareerPayments }

      it "returns the correct content block" do
        expect(helper.send_your_application(claim)).to include(I18n.t("early_career_payments.check_your_answers.heading_send_application"), "h2", "govuk-heading-m")
      end
    end
  end

  describe "#statement(claim)" do
    context "with StudentLoans policy" do
      let(:policy) { StudentLoans }

      it "returns the correct content block" do
        expect(helper.statement(claim)).to include(I18n.t("check_your_answers.statement"), "p", "govuk-body")
      end
    end

    context "with EarlyCareerPaymenst policy" do
      let(:policy) { EarlyCareerPayments }

      it "returns the correct content block" do
        expect(helper.statement(claim)).to include(I18n.t("early_career_payments.check_your_answers.statement"), "p", "govuk-body")
      end
    end
  end

  describe "#submit_text(claim)" do
    context "with StudentLoans policy" do
      let(:policy) { StudentLoans }

      it "returns the correct content block" do
        expect(helper.submit_text(claim)).to include(I18n.t("check_your_answers.btn_text"))
      end
    end

    context "with EarlyCareerPaymenst policy" do
      let(:policy) { EarlyCareerPayments }

      it "returns the correct content block" do
        expect(helper.submit_text(claim)).to include(I18n.t("early_career_payments.check_your_answers.btn_text"))
      end
    end
  end
end
