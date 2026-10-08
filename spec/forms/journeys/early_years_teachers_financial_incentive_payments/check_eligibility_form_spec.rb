require "rails_helper"

RSpec.describe Journeys::EarlyYearsTeachersFinancialIncentivePayments::CheckEligibilityForm, type: :model do
  let(:journey) { Journeys::EarlyYearsTeachersFinancialIncentivePayments }
  let(:journey_session) { create(:eytfi_session, answers:) }
  let(:answers) { build(:eytfi_answers) }

  let(:params) do
    ActionController::Parameters.new(claim: {})
  end

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "#load_current_value" do
    context "when a previous answer exists" do
      let(:answers) { build(:eytfi_answers, fifty_percent_time_as_eyt: true, not_subject_to_performance_and_disciplinary: true) }

      it "prefills the radio button from the persisted eligibility answer" do
        expect(subject.send(:load_current_value, :meets_eligibility_criteria)).to be(true)
      end
    end
  end

  describe "#save" do
    context "when no value is submitted" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {}
        )
      end

      it "requires the user to select an answer" do
        expect(subject).not_to be_valid
        expect(subject.errors[:meets_eligibility_criteria]).to include("Select yes or no to tell us if you meet the eligibility criteria")
      end
    end

    context "when the user selects yes" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            meets_eligibility_criteria: "true"
          }
        )
      end

      it "persists true for both attributes" do
        expect { subject.save }
          .to change { journey_session.reload.answers.fifty_percent_time_as_eyt }.from(nil).to(true)
          .and change { journey_session.reload.answers.not_subject_to_performance_and_disciplinary }.from(nil).to(true)
      end
    end

    context "when the user selects no" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            meets_eligibility_criteria: "false"
          }
        )
      end

      it "persists false for both attributes" do
        expect { subject.save }
          .to change { journey_session.reload.answers.fifty_percent_time_as_eyt }.from(nil).to(false)
          .and change { journey_session.reload.answers.not_subject_to_performance_and_disciplinary }.from(nil).to(false)
      end
    end

    context "when a previously-yes answer is changed to no" do
      let(:answers) { build(:eytfi_answers, fifty_percent_time_as_eyt: true, not_subject_to_performance_and_disciplinary: true) }

      let(:params) do
        ActionController::Parameters.new(
          claim: {
            meets_eligibility_criteria: "false"
          }
        )
      end

      it "persists false for both attributes" do
        expect { subject.save }
          .to change { journey_session.reload.answers.fifty_percent_time_as_eyt }.from(true).to(false)
          .and change { journey_session.reload.answers.not_subject_to_performance_and_disciplinary }.from(true).to(false)
      end
    end
  end
end
