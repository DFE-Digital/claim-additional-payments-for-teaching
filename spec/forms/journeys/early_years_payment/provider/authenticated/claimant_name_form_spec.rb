require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::ClaimantNameForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }
  let(:journey_session) { create(:early_years_payment_provider_authenticated_session) }
  let(:first_name) { nil }
  let(:surname) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        first_name:,
        surname:
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    # First name validations
    it { should validate_presence_of(:first_name).with_message("Enter employee’s first name") }
    it { should validate_length_of(:first_name).is_at_most(100).with_message("Employee’s first name must be less than 100 characters") }
    it { should allow_value("O'Brian").for(:first_name) }
    %w[* | { ^ /].each do |char|
      it { should_not allow_value(char).for(:first_name).with_message("Employee’s first name cannot contain special characters") }
    end

    # Surname validations
    it { should validate_presence_of(:surname).with_message("Enter employee’s last name") }
    it { should validate_length_of(:surname).is_at_most(100).with_message("Employee’s last name must be less than 100 characters") }
    it { should_not allow_value("5").for(:surname).with_message("Employee’s last name cannot contain special characters") }
    it { should allow_value("O'Brian").for(:surname) }
  end

  describe "#save" do
    let(:first_name) { "Bobby" }
    let(:surname) { "Bobberson" }

    it "updates the journey session" do
      expect { subject.save }.to(
        change { journey_session.answers.first_name }.to(first_name).and(
          change { journey_session.answers.surname }.to(surname)
        ).and(
          change { journey_session.answers.practitioner_first_name }.to(first_name)
        ).and(
          change { journey_session.answers.practitioner_surname }.to(surname)
        )
      )
    end
  end
end
