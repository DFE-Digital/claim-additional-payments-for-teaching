require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::StartDateForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }
  let(:journey_session) { create(:early_years_payment_provider_authenticated_session) }
  let(:day) { nil }
  let(:month) { nil }
  let(:year) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        "start_date(1i)" => year.to_s,
        "start_date(2i)" => month.to_s,
        "start_date(3i)" => day.to_s
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    it { should validate_presence_of(:start_date).with_message("Provide a date in the format 27 3 2024") }
  end

  describe "#save" do
    let(:day) { 1 }
    let(:month) { 1 }
    let(:year) { Time.zone.today.year }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.start_date }
        .to(Date.new(year, month, day))
      )
    end
  end
end
