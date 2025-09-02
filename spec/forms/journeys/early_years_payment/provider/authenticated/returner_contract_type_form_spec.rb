require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::ReturnerContractTypeForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }
  let(:journey_session) do
    create(
      :early_years_payment_provider_authenticated_session,
      answers: {
        first_name: "John",
        surname: "Doe"
      }
    )
  end
  let(:returner_contract_type) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        returner_contract_type:
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    context "when no option selected" do
      it do
        is_expected.not_to(
          allow_value(nil)
          .for(:returner_contract_type)
          .with_message("Select the type of contract John Doe had in their previous role")
        )
      end
    end
  end

  describe "#save" do
    let(:returner_contract_type) { "permanent" }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.returner_contract_type }
        .to(returner_contract_type)
      )
    end
  end
end
