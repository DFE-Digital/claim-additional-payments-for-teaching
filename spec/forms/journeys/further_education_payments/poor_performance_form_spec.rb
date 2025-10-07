require "rails_helper"

RSpec.describe PoorPerformanceForm do
  subject(:form) { described_class.new(journey_session:, journey:, params:) }

  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }

  let(:slug) { "poor-performance" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }

  let(:subject_to_formal_performance_action) { "true" }
  let(:subject_to_disciplinary_action) { "true" }
  let(:claim_params) { {subject_to_formal_performance_action:, subject_to_disciplinary_action:} }

  it { expect(form).to be_a(Form) }

  describe "validations" do
    context "subject_to_formal_performance_action" do
      context "when nil" do
        let(:subject_to_formal_performance_action) { nil }

        it "cannot be nil" do
          expect(form).to be_invalid
          expect(form.errors[:subject_to_formal_performance_action])
            .to eq(["Select yes if you are currently subject to any formal performance measures as a result of continuous poor teaching standards"])
        end
      end

      context "when true" do
        let(:subject_to_formal_performance_action) { "true" }

        it { is_expected.to be_valid }
      end

      context "when false" do
        let(:subject_to_formal_performance_action) { "false" }
        it { is_expected.to be_valid }
      end
    end

    context "subject_to_disciplinary_action" do
      context "when nil" do
        let(:subject_to_disciplinary_action) { nil }

        it "cannot be nil" do
          expect(form).to be_invalid
          expect(form.errors[:subject_to_disciplinary_action])
            .to eq(["Select yes if you are currently subject to disciplinary action"])
        end
      end

      context "when true" do
        let(:subject_to_disciplinary_action) { "true" }

        it { is_expected.to be_valid }
      end

      context "when false" do
        let(:subject_to_disciplinary_action) { "false" }
        it { is_expected.to be_valid }
      end
    end
  end
end
