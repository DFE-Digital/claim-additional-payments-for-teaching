require "rails_helper"

RSpec.describe PoorPerformanceForm do
  subject(:form) { described_class.new(journey_session:, journey:, params:) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }
  let(:journey_session) { create(:additional_payments_session) }
  let(:slug) { "poor-performance" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }
  let(:claim_params) { {subject_to_formal_performance_action: "true", subject_to_disciplinary_action: "false"} }

  it { expect(form).to be_a(Form) }

  describe "validations" do
    context "subject_to_formal_performance_action" do
      it "cannot be nil" do
        form.subject_to_formal_performance_action = nil

        expect(form).to be_invalid
        expect(form.errors[:subject_to_formal_performance_action])
          .to eq([form.i18n_errors_path("performance.inclusion")])
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
          .to eq([form.i18n_errors_path("disciplinary.inclusion")])
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
        expect {
          form.save
        }.to change { journey_session.answers.subject_to_formal_performance_action }.to(true)
          .and change { journey_session.answers.subject_to_disciplinary_action }.to(false)
      end
    end

    context "invalid params" do
      let(:claim_params) { {subject_to_formal_performance_action: "", subject_to_disciplinary_action: "false"} }

      it "does not update the attributes on the claim" do
        expect { form.save }.to not_change { journey_session.reload.answers.subject_to_formal_performance_action }
          .and not_change { journey_session.reload.answers.subject_to_disciplinary_action }
      end
    end
  end

  describe "#clear_answers_from_session" do
    let(:journey_session) { create(:further_education_payments_session, answers:) }
    let(:answers) { build(:further_education_payments_answers, answers_hash) }

    let(:answers_hash) do
      {
        subject_to_formal_performance_action: true,
        subject_to_disciplinary_action: true
      }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.subject_to_formal_performance_action }.from(true).to(nil)
        .and change { journey_session.reload.answers.subject_to_disciplinary_action }.from(true).to(nil)
    end
  end
end
