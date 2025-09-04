require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::ReturnerForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }
  let(:journey_session) do
    create(
      :early_years_payment_provider_authenticated_session,
      answers: {
        first_name: "John",
        surname: "Doe",
        start_date: 1.day.ago
      }
    )
  end
  let(:returning_within_6_months) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        returning_within_6_months:
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    around do |example|
      travel_to(Date.new(2025, 9, 2)) do
        example.run
      end
    end

    it do
      is_expected.not_to(
        allow_value(returning_within_6_months)
        .for(:returning_within_6_months)
        .with_message("Select yes if John Doe worked in early years between 1 March 2025 and 1 September 2025")
      )
    end
  end

  describe "#save" do
    context "when returning within 6 months" do
      let(:returning_within_6_months) { "true" }

      it "updates the journey session" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.returning_within_6_months }.to(true)
        )
      end
    end

    context "when not returning within 6 months" do
      let(:returning_within_6_months) { "false" }

      let(:journey_session) do
        create(
          :early_years_payment_provider_authenticated_session,
          answers:
        )
      end

      let(:answers) do
        {
          returner_worked_with_children: true,
          returner_contract_type: "casual or temporary"
        }
      end

      it "updates the journey session and resets dependent answers" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.returning_within_6_months }.to(false)
          .and(change { journey_session.answers.returner_worked_with_children }.to(nil)
          .and(change { journey_session.answers.returner_contract_type }.to(nil)))
        )
      end
    end
  end
end
