require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::ReturnerWorkedWithChildrenForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }
  let(:journey_session) { create(:early_years_payment_provider_authenticated_session) }
  let(:returner_worked_with_children) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        returner_worked_with_children:
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    it do
      is_expected.not_to(
        allow_value(returner_worked_with_children)
        .for(:returner_worked_with_children)
        .with_message("You must select an option below to continue")
      )
    end
  end

  describe "#save" do
    context "when returner worked with children" do
      let(:returner_worked_with_children) { "true" }

      it "updates the journey session" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.returner_worked_with_children }.to(true)
        )
      end
    end

    context "when returner did work with children" do
      let(:returner_worked_with_children) { "false" }
      let(:journey_session) do
        create(
          :early_years_payment_provider_authenticated_session,
          answers:
        )
      end
      let(:answers) do
        {
          returner_contract_type: "casual or temporary"
        }
      end

      it "updates the journey session and resets dependent answers" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.returner_worked_with_children }.to(false)
          .and(change { journey_session.answers.returner_contract_type }.to(nil))
        )
      end
    end
  end
end
