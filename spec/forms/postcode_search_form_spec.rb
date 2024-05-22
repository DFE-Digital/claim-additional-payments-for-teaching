require "rails_helper"

RSpec.describe PostcodeSearchForm, type: :model do
  subject { described_class.new(claim:, journey:, params:, journey_session:) }

  let(:claim) { CurrentClaim.new(claims: [create(:claim)]) }
  let(:journey) { Journeys::AdditionalPaymentsForTeaching }
  let(:journey_session) { build(:additional_payments_session) }
  let(:params) { ActionController::Parameters.new }

  before do
    allow_any_instance_of(OrdnanceSurvey::Client).to receive_message_chain(:api, :search_places, :index).and_return([double])
  end

  it { is_expected.to validate_presence_of(:postcode).with_message("Enter a real postcode") }

  context "when the postcode is too long" do
    let(:params) { ActionController::Parameters.new(claim: {postcode: "SW1A1AAAAAAA"}) }

    it { is_expected.to be_invalid }

    it "adds a descriptive error message" do
      subject.validate
      expect(subject.errors[:postcode]).to include("Postcode must be 11 characters or less")
    end
  end

  context "with a non-existent postcode" do
    let(:params) { ActionController::Parameters.new(claim: {postcode: "AB1 C23"}) }

    it { is_expected.to be_invalid }

    it "adds a descriptive error message" do
      subject.validate
      expect(subject.errors[:postcode]).to include("Enter a postcode in the correct format")
    end
  end

  context "with a real postcode" do
    let(:params) { ActionController::Parameters.new(claim: {postcode: "SW1A 1AA"}) }

    it { is_expected.to be_valid }
  end

  context "when the postcode returns no place matches" do
    let(:params) { ActionController::Parameters.new(claim: {postcode: "SW1B 1AA"}) }

    before do
      allow_any_instance_of(OrdnanceSurvey::Client).to receive_message_chain(:api, :search_places, :index).and_return(nil)
    end

    it { is_expected.to be_invalid }

    it "adds an address not found error" do
      subject.validate
      expect(subject.errors[:postcode]).to include("Address not found")
    end
  end
end
