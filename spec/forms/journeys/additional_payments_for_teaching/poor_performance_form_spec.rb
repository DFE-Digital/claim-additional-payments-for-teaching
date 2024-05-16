require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::PoorPerformanceForm do
  subject(:form) { described_class.new(claim:, journey_session:, journey:, params:) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }
  let(:journey_session) { build(:additional_payments_session) }
  let(:ecp_claim) { build(:claim, policy: Policies::EarlyCareerPayments) }
  let(:lupp_claim) { build(:claim, policy: Policies::LevellingUpPremiumPayments) }
  let(:claim) { CurrentClaim.new(claims: [ecp_claim, lupp_claim]) }
  let(:slug) { "poor-performance" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }
  let(:claim_params) { {subject_to_formal_performance_action: "true", subject_to_disciplinary_action: "false"} }

  it { expect(form).to be_a(Form) }

  context "with unpermitted params" do
    let(:claim_params) { {unpermitted_param: ""} }

    it "raises an error" do
      expect { form }.to raise_error ActionController::UnpermittedParameters
    end
  end

  describe "validations" do
    context "subject_to_formal_performance_action" do
      it "cannot be nil" do
        form.subject_to_formal_performance_action = nil

        expect(form).to be_invalid
        expect(form.errors[:subject_to_formal_performance_action])
          .to eq([form.i18n_errors_path("subject_to_formal_performance_action.inclusion")])
      end

      it "can be true or false" do
        form.subject_to_formal_performance_action = true
        expect(form).to be_valid

        form.subject_to_formal_performance_action = false
        expect(form).to be_valid
      end
    end

    context "subject_to_disciplinary_action" do
      it "cannot be nil" do
        form.subject_to_disciplinary_action = nil

        expect(form).to be_invalid
        expect(form.errors[:subject_to_disciplinary_action])
          .to eq([form.i18n_errors_path("subject_to_disciplinary_action.inclusion")])
      end

      it "can be true or false" do
        form.subject_to_disciplinary_action = true
        expect(form).to be_valid

        form.subject_to_disciplinary_action = false
        expect(form).to be_valid
      end
    end
  end

  context "#save" do
    context "valid params" do
      let(:claim_params) { {subject_to_formal_performance_action: "true", subject_to_disciplinary_action: "false"} }

      it "updates the attributes on the claim" do
        expect { form.save }.to change { claim.eligibility.subject_to_formal_performance_action }.to(true)
          .and change { claim.eligibility.subject_to_disciplinary_action }.to(false)
      end
    end

    context "invalid params" do
      let(:claim_params) { {subject_to_formal_performance_action: "", subject_to_disciplinary_action: "false"} }

      it "does not update the attributes on the claim" do
        expect { form.save }.to not_change { claim.eligibility.subject_to_formal_performance_action }
          .and not_change { claim.eligibility.subject_to_disciplinary_action }
      end
    end
  end
end
