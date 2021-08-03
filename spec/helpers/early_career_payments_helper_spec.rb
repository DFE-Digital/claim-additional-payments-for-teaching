require "rails_helper"

describe EarlyCareerPaymentsHelper do
  let(:claim) { build(:claim, policy: policy, eligibility: eligibility) }
  let(:eligibility) { build(:early_career_payments_eligibility) }

  describe "#ineligible_heading" do
    context "A generic ineligible ECP claim" do
      let(:policy) { EarlyCareerPayments }

      it "generates the generic heading for an ineligible claim" do
        expect(helper.ineligible_heading(claim)).to include I18n.t("early_career_payments.ineligible.heading")
      end
    end

    context "An ineligible ECP claim based on poor performance" do
      let(:policy) { EarlyCareerPayments }
      let(:eligibility) { build(:early_career_payments_eligibility, subject_to_formal_performance_action: true) }

      it "generates the correct heading for an ineligible claim based on poor performance" do
        expect(helper.ineligible_heading(claim)).to include I18n.t("early_career_payments.ineligible.heading")
      end
    end

    context "An ineligible ECP claim based on an ineligible school" do
      let(:policy) { EarlyCareerPayments }
      let(:eligibility) { build(:early_career_payments_eligibility, current_school: School.find(ActiveRecord::FixtureSet.identify(:bradford_grammar_school, :uuid))) }

      it "generates the correct heading for an ineligible claim based on an ineligible school" do
        expect(helper.ineligible_heading(claim)).to include I18n.t("early_career_payments.ineligible.school_heading")
      end
    end
  end

  describe "#one_time_password_validity_duration" do
    context "with 'OTP_PASSWORD_DRIFT' constant set" do
      it "reports '1 minute' when 60 (seconds)" do
        stub_const("OneTimePassword::OTP_PASSWORD_DRIFT", 60)

        expect(helper.one_time_password_validity_duration).to eq("1 minute")
      end

      it "reports '1 minute' when 60 (seconds)" do
        stub_const("OneTimePassword::OTP_PASSWORD_DRIFT", 900)

        expect(helper.one_time_password_validity_duration).to eq("15 minutes")
      end
    end
  end
end
