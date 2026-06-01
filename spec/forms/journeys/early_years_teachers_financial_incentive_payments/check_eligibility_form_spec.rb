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

  describe "#save" do
    context "when both boxes are checked" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            fifty_percent_time_as_eyt: "1",
            not_subject_to_performance_and_disciplinary: "1"
          }
        )
      end

      it "persists true for both attributes" do
        expect { subject.save }
          .to change { journey_session.reload.answers.fifty_percent_time_as_eyt }.from(nil).to(true)
          .and change { journey_session.reload.answers.not_subject_to_performance_and_disciplinary }.from(nil).to(true)
      end
    end

    context "when neither box is checked" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            fifty_percent_time_as_eyt: "0",
            not_subject_to_performance_and_disciplinary: "0"
          }
        )
      end

      it "persists false for both attributes" do
        expect { subject.save }
          .to change { journey_session.reload.answers.fifty_percent_time_as_eyt }.from(nil).to(false)
          .and change { journey_session.reload.answers.not_subject_to_performance_and_disciplinary }.from(nil).to(false)
      end
    end

    context "when unchecking a previously checked box" do
      let(:answers) { build(:eytfi_answers, fifty_percent_time_as_eyt: true, not_subject_to_performance_and_disciplinary: true) }

      let(:params) do
        ActionController::Parameters.new(
          claim: {
            fifty_percent_time_as_eyt: "0",
            not_subject_to_performance_and_disciplinary: "0"
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
