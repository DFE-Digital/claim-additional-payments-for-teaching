require "rails_helper"

RSpec.describe Claims::EmailAddressHelper do
  let(:claim) { build(:claim, policy: policy) }

  describe "#email_govuk_hint" do
    context "with a StudentLoans policy" do
      let(:policy) { StudentLoans }

      it "generates the correct hint based on translation for 'email_address_hint'" do
        expect(helper.email_govuk_hint(claim)).to include I18n.t("questions.email_address_hint")
      end
    end

    context "with a EarlyCareerPayments policy" do
      let(:policy) { EarlyCareerPayments }

      it "generates the correct hint based on translation for 'email_address_hint1' and 'email_address_hint2'" do
        expect(helper.email_govuk_hint(claim)).to include(I18n.t("early_career_payments.email_address_hint1"), I18n.t("early_career_payments.email_address_hint2"), "email-address-hint", "govuk-hint")
      end
    end
  end

  describe "#personal_details_caption" do
    context "with a StudentLoans policy" do
      let(:policy) { StudentLoans }

      it "is not generated to be rendered" do
        expect(helper.personal_details_caption(claim)).to be_nil
      end
    end

    context "with EarlyCareerPayments policy" do
      let(:policy) { EarlyCareerPayments }

      it "generates the correct text to display" do
        expect(helper.personal_details_caption(claim)).to include(I18n.t("early_career_payments.personal_details"), "govuk-caption-xl")
      end
    end
  end
end
