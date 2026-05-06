require "rails_helper"

RSpec.describe Journeys::EarlyYearsTeachersFinancialIncentivePayments::TeachingQualificationConfirmationForm, type: :model do
  let(:journey) { Journeys::EarlyYearsTeachersFinancialIncentivePayments }
  let(:journey_session) { create(:eytfi_session, answers:) }
  let(:answers) { build(:eytfi_answers) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {}
    )
  end

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "validations" do
    describe "#teaching_qualification_confirmation" do
      it do
        is_expected.to validate_presence_of(
          :teaching_qualification_confirmation
        ).with_message("Select yes if you hold one of the listed qualifications")
      end
    end
  end

  describe "#save" do
    let(:params) do
      ActionController::Parameters.new(
        claim: {
          teaching_qualification_confirmation: "true"
        }
      )
    end

    it "persists form to session" do
      expect {
        subject.save
      }.to change { journey_session.reload.answers.teaching_qualification_confirmation }.from(nil).to(true)
    end
  end
end
