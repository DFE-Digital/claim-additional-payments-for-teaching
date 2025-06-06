require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::TeacherReferenceNumberForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:answers_hash) { {} }

  let(:params) do
    ActionController::Parameters.new
  end

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end
end
