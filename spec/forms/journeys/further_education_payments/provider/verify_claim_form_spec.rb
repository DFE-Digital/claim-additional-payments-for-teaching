require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::Provider::VerifyClaimForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments::Provider }

  let(:journey_session) do
    create(:further_education_payments_provider_session)
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
  end
end
