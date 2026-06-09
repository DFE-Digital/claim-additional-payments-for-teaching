require "rails_helper"

RSpec.describe PostcodeSearchForm, type: :model do
  subject do
    described_class.new(
      journey: journey,
      params: params,
      journey_session: journey_session
    )
  end

  let(:journey) { Journeys::TargetedRetentionIncentivePayments }
  let(:journey_session) { build(:targeted_retention_incentive_payments_session) }
  let(:params) { ActionController::Parameters.new }

  before do
    allow_any_instance_of(OrdnanceSurvey::Client).to receive_message_chain(:api, :search_places, :index).and_return([double])
  end

  it { is_expected.to validate_presence_of(:postcode).with_message("Enter a postcode, for example NE1 6EE") }

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

  context "when the postcode lookup failed" do
    let(:params) { ActionController::Parameters.new(claim: {postcode: "SW1B 1AA"}) }

    before do
      allow_any_instance_of(OrdnanceSurvey::Client).to receive_message_chain(:api, :search_places, :index)
        .and_raise(OrdnanceSurvey::Client::ResponseError)
    end

    it "stores state to session" do
      subject.validate
      expect(journey_session.reload.answers.ordnance_survey_error).to be_truthy
    end
  end

  describe "#save" do
    let(:answers) do
      attributes_for(
        :targeted_retention_incentive_payments_answers,
        skip_postcode_search: false,
        address_line_1: "1 High Street",
        address_line_2: "Town Centre",
        address_line_3: "Springfield",
        address_line_4: "County",
        postcode: "SW1A 1AA"
      )
    end
    let(:journey_session) { build(:targeted_retention_incentive_payments_session, answers:) }
    let(:form) do
      described_class.new(
        journey: journey,
        params: params,
        journey_session: journey_session
      )
    end

    context "when skipping postcode search" do
      let(:params) do
        ActionController::Parameters.new(claim: {skip_postcode_search: true})
      end

      it "clears selected address fields when switching to manual address entry" do
        expect(form.save).to be_truthy

        saved_answers = journey_session.reload.answers
        expect(saved_answers.skip_postcode_search).to be(true)
        expect(saved_answers.address_line_1).to be_nil
        expect(saved_answers.address_line_2).to be_nil
        expect(saved_answers.address_line_3).to be_nil
        expect(saved_answers.address_line_4).to be_nil
      end
    end

    context "when searching with a new postcode" do
      let(:params) { ActionController::Parameters.new(claim: {postcode: "SW1B 1AA", skip_postcode_search: false}) }

      it "clears any existing address fields and stores the new postcode" do
        expect(form.save).to be_truthy

        saved_answers = journey_session.reload.answers
        expect(saved_answers.skip_postcode_search).to be(false)
        expect(saved_answers.address_line_1).to be_nil
        expect(saved_answers.address_line_2).to be_nil
        expect(saved_answers.address_line_3).to be_nil
        expect(saved_answers.address_line_4).to be_nil
        expect(saved_answers.postcode).to eq("SW1B 1AA")
      end
    end
  end
end
