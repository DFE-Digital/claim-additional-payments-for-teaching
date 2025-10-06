require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::SelectProvisionForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }
  let(:college) { create(:school) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        possible_school_id:
      }
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
    let(:possible_school_id) { nil }

    it do
      is_expected.not_to(
        allow_value("")
        .for(:possible_school_id)
        .with_message("Select where you are employed")
      )
    end
  end

  describe "#save" do
    let(:possible_school_id) { college.id }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.school_id }.to(college.id)
      )
    end
  end
end
