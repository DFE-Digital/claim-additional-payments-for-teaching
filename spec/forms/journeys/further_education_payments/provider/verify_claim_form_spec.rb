require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::Provider::VerifyClaimForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments::Provider }

  let(:claim) { create(:further_education_payments_eligibility).claim }

  let(:journey_session) do
    create(
      :further_education_payments_provider_session,
      answers: {
        claim_id: claim.id,
        dfe_sign_in_uid: "123"
      }
    )
  end

  let(:params) { ActionController::Parameters.new }

  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    it do
      is_expected.to validate_acceptance_of(:declaration)
    end

    it "validates all assertions are answered" do
      form.validate

      form.assertions.each do |assertion|
        expect(assertion.errors[:outcome]).to eq(["Select an option"])
      end
    end
  end
end
