require "rails_helper"

RSpec.describe(
  Journeys::EarlyYearsTeachersFinancialIncentivePayments::SessionAnswers
) do
  describe "#hmrc_employment_check_passed" do
    it "returns nil until the job completes" do
      journey_session = create(:eytfi_session)

      expect(journey_session.answers.hmrc_employment_check_passed).to be_nil
    end

    it "checks the current nursery without changing the stored response" do
      nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")
      other_nursery = create(:eligible_eytfi_provider, name: "Other nursery")
      response_body = {
        employments: [{employer: {name: "Springfield nursery"}}]
      }.to_json
      journey_session = create(
        :eytfi_session,
        answers: {
          nursery_id: nursery.id,
          hmrc_response_status: 200,
          hmrc_response_body: response_body
        }
      )
      answers = journey_session.answers

      expect(answers.hmrc_employment_check_passed).to eq(true)

      answers.update!(nursery_id: other_nursery.id)

      expect(answers.hmrc_employment_check_passed).to eq(false)
      expect(journey_session.reload.answers.hmrc_response_body)
        .to eq(response_body)
      expect(journey_session.answers.attributes)
        .not_to have_key("hmrc_employment_check_passed")
    end

    it "returns false when no nursery is selected" do
      journey_session = create(
        :eytfi_session,
        answers: {
          hmrc_response_status: 200,
          hmrc_response_body: {employments: []}.to_json
        }
      )

      expect(journey_session.answers.hmrc_employment_check_passed).to eq(false)
    end

    it "returns nil when no HTTP response is available" do
      nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")
      journey_session = create(
        :eytfi_session,
        answers: {
          nursery_id: nursery.id,
          hmrc_response_status: nil,
          hmrc_response_body: nil
        }
      )

      expect(journey_session.answers.hmrc_employment_check_passed).to be_nil
    end

    it "rejects an error status even if the body contains a matching employer" do
      nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")
      journey_session = create(
        :eytfi_session,
        answers: {
          nursery_id: nursery.id,
          hmrc_response_status: 500,
          hmrc_response_body: {
            employments: [{employer: {name: "Springfield nursery"}}]
          }.to_json
        }
      )

      expect(journey_session.answers.hmrc_employment_check_passed).to eq(false)
    end
  end

  describe "#hmrc_response_received?" do
    it "returns true when only the response status is present" do
      answers = described_class.new(hmrc_response_status: 404)

      expect(answers.hmrc_response_received?).to eq(true)
    end

    it "returns true when only the response body is present" do
      answers = described_class.new(hmrc_response_body: "not JSON")

      expect(answers.hmrc_response_received?).to eq(true)
    end

    it "returns false when neither status nor body is present" do
      answers = described_class.new(hmrc_response_body: "")

      expect(answers.hmrc_response_received?).to eq(false)
    end
  end
end
