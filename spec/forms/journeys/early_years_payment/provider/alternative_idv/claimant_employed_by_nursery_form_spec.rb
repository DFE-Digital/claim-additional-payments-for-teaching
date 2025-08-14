require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::AlternativeIdv::ClaimantEmployedByNurseryForm, type: :model do
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
      eligibility_attributes: {
        nursery_urn: nursery.urn
      }
    )
  end

  let(:journey_session) do
    create(
      :early_years_payment_provider_alternative_idv_session,
      answers: {
        claim_reference: claim.reference
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

    describe "claimant_bank_details_match" do
      let(:params) do
        {}
      end

      it do
        is_expected.not_to(
          allow_value(nil).for(:claimant_employed_by_nursery)
        )
      end

      it do
        is_expected.to(
          allow_value(true).for(:claimant_employed_by_nursery)
        )
      end

      it do
        is_expected.to(
          allow_value(false).for(:claimant_employed_by_nursery)
        )
      end
    end
  end
end
