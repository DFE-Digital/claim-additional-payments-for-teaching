require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::ProviderEnteredContractTypeForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }

  let(:journey_session) do
    create(:early_years_payment_provider_authenticated_session)
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: journey,
      params: ActionController::Parameters.new(claim: params)
    )
  end

  let(:params) { {} }

  describe "validations" do
    subject { form }

    describe "provider_entered_contract_type" do
      it do
        is_expected.to(
          validate_inclusion_of(:provider_entered_contract_type)
          .in_array(
            %w[
              permanent
              casual_or_temporary
              voluntary_or_unpaid
              agency_work_and_apprenticeship_roles
            ]
          )
          .with_message("You must select an option below to continue")
        )
      end
    end
  end
end
