require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::SelectProvisionForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }
  let(:college) { create(:school) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        school_id:
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
    let(:school_id) { nil }

    it do
      is_expected.not_to(
        allow_value("")
        .for(:school_id)
        .with_message("Select the college you teach at")
      )
    end
  end

  describe "#save" do
    let(:school_id) { college.id }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.school_id }.to(college.id)
      )
    end
  end
end
