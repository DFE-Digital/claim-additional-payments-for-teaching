require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::TeacherReferenceNumberForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:answers_hash) { {} }

  let(:params) do
    ActionController::Parameters.new()
  end

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "#clear_answers_from_session" do
    let(:answers_hash) do
      {
        teacher_reference_number: "1234567"
      }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.teacher_reference_number }.from("1234567").to(nil)
    end
  end
end
