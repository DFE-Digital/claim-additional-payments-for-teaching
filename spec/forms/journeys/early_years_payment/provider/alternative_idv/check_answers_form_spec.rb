require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::AlternativeIdv::CheckAnswersForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::AlternativeIdv }

  let(:nursery) do
    create(:eligible_ey_provider, nursery_name: "Springfield Nursery")
  end

  let(:claim) do
    create(
      :claim,
      policy: Policies::EarlyYearsPayments,
      first_name: "Edna",
      surname: "Krabappel",
      identity_confirmed_with_onelogin: false,
      eligibility_attributes: {
        nursery_urn: nursery.urn,
        alternative_idv_reference: "1234567890"
      }
    )
  end

  let(:journey_session) do
    create(
      :early_years_payment_provider_alternative_idv_session,
      answers: {
        alternative_idv_reference: claim.eligibility.alternative_idv_reference
      }
    )
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: journey,
      params: ActionController::Parameters.new(claim: params)
    )
  end

  describe "validations" do
    subject { form }

    describe "claimant_employment_check_declaration" do
      let(:params) do
        {}
      end

      it do
        is_expected.to(
          validate_acceptance_of(:claimant_employment_check_declaration)
          .with_message(
            "Tick the box to declare that the information provided in this " \
            "form is correct"
          )
        )
      end
    end
  end
end
