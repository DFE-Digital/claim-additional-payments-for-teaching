require "rails_helper"

RSpec.describe(
  Journeys::EarlyYearsTeachersFinancialIncentivePayments::SessionAnswers
) do
  describe "#hmrc_employment_check_passed?" do
    it "returns nil until the job completes" do
      journey_session = create(:eytfi_session)

      expect(journey_session.answers.hmrc_employment_check_passed?).to be false
    end

    it "checks the current nursery without changing the stored response" do
      nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")
      other_nursery = create(:eligible_eytfi_provider, name: "Other nursery")
      response_body = {
        employments: [
          {
            employer: {
              name: "Springfield nursery",
              address: {
                postcode: nursery.postcode
              }
            }
          }
        ]
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

      expect(answers.hmrc_employment_check_passed?).to eq(true)

      answers.update!(nursery_id: other_nursery.id)

      expect(answers.hmrc_employment_check_passed?).to eq(false)
      expect(journey_session.reload.answers.hmrc_response_body)
        .to eq(response_body)
    end

    it "returns false when no nursery is selected" do
      journey_session = create(
        :eytfi_session,
        answers: {
          hmrc_response_status: 200,
          hmrc_response_body: {employments: []}.to_json
        }
      )

      expect(journey_session.answers.hmrc_employment_check_passed?).to eq(false)
    end

    it "returns false when no HTTP response is available" do
      nursery = create(:eligible_eytfi_provider, name: "Springfield nursery")
      journey_session = create(
        :eytfi_session,
        answers: {
          nursery_id: nursery.id,
          hmrc_response_status: nil,
          hmrc_response_body: nil
        }
      )

      expect(journey_session.answers.hmrc_employment_check_passed?).to be(false)
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

      expect(journey_session.answers.hmrc_employment_check_passed?).to eq(false)
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

  describe "#previous_claim" do
    before do
      create(
        :journey_configuration,
        :early_years_teachers_financial_incentive_payments,
        current_academic_year:
      )
    end

    let(:claim_2025_2026) do
      create(
        :claim,
        :submitted,
        policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
        academic_year: AcademicYear.new(2025),
        onelogin_uid: "abc123"
      )
    end

    let(:claim_2026_2027) do
      create(
        :claim,
        :submitted,
        policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
        academic_year: AcademicYear.new(2026),
        onelogin_uid: "abc123"
      )
    end

    let(:claim_2027_2028) do
      create(
        :claim,
        :submitted,
        policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
        academic_year: AcademicYear.new(2027),
        onelogin_uid: "abc123"
      )
    end

    subject do
      described_class.new(
        teacher_auth_one_login_uid: "abc123"
      )
    end

    context "when configured year is 2025/2026" do
      let(:current_academic_year) { AcademicYear.new(2025) }

      it "returns only claims in 2025/2026" do
        expect(subject.previous_claim).to be_nil
      end

      it "returns only claims in 2025/2026" do
        claim_2025_2026

        expect(subject.previous_claim).to eql(claim_2025_2026)
      end
    end

    context "when configured year is 2026/2027" do
      let(:current_academic_year) { AcademicYear.new(2026) }

      it "returns claims in [2025/2026, 2026/2027]" do
        expect(subject.previous_claim).to be_nil
      end

      it "returns claims in [2025/2026, 2026/2027]" do
        claim_2025_2026

        expect(subject.previous_claim).to eql(claim_2025_2026)
      end

      it "returns claims in [2025/2026, 2026/2027]" do
        claim_2026_2027

        expect(subject.previous_claim).to eql(claim_2026_2027)
      end
    end

    context "when configured year is 2027/2028" do
      let(:current_academic_year) { AcademicYear.new(2027) }

      it "returns only claims in 2027/2028" do
        claim_2025_2026
        claim_2026_2027

        expect(subject.previous_claim).to be_nil
      end

      it "returns only claims in 2027/2028" do
        claim_2027_2028

        expect(subject.previous_claim).to eql(claim_2027_2028)
      end
    end
  end
end
