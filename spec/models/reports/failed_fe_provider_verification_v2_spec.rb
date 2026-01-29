require "rails_helper"

RSpec.describe Reports::FailedFeProviderVerificationV2 do
  include ActionView::Helpers::NumberHelper

  around :each do |example|
    freeze_time(Time.new(2026, 1, 20)) do
      example.run
    end
  end

  let!(:claim_passed_fe_provider_verification) do
    create(
      :claim,
      :submitted,
      :further_education,
      :current_academic_year
    )
  end

  let!(:task_passed_fe_provider_verification) do
    create(
      :task,
      :passed,
      claim: claim_passed_fe_provider_verification,
      name: "fe_provider_verification_v2"
    )
  end

  let!(:claim_failed_fe_provider_verification) do
    create(
      :claim,
      :submitted,
      :rejected,
      :further_education,
      :current_academic_year,
      eligibility: eligibility_failed_fe_provider_verification
    )
  end

  let!(:eligibility_failed_fe_provider_verification) do
    create(
      :further_education_payments_eligibility,
      :with_award_amount,
      :provider_verifiable,
      :provider_verification_employment_checked,
      :provider_verification_started,
      :provider_verification_completed
    )
  end

  let!(:task_failed_fe_provider_verification) do
    create(
      :task,
      :failed,
      claim: claim_failed_fe_provider_verification,
      name: "fe_provider_verification_v2",
      data: {
        failed_checks: ["performance_measures", "disciplinary_action"]
      }
    )
  end

  describe "#to_csv" do
    it "only includes claims that failed FE provider task" do
      csv = subject.to_csv

      expect(csv).not_to include(claim_passed_fe_provider_verification.reference)
      expect(csv).to include(claim_failed_fe_provider_verification.reference)
    end

    it "includes headers" do
      csv = subject.to_csv
      rows = CSV.parse(csv, headers: true)

      expect(rows.headers).to eql described_class::HEADERS
    end

    it "includes data" do
      csv = subject.to_csv
      rows = CSV.parse(csv, headers: true)

      expect(rows[0]["Claim reference"]).to eql(claim_failed_fe_provider_verification.reference)
      expect(rows[0]["Full name"]).to eql(claim_failed_fe_provider_verification.full_name)
      expect(rows[0]["Claim amount"]).to eql(number_to_currency(claim_failed_fe_provider_verification.award_amount, precision: 0))
      expect(rows[0]["Claim status"]).to eql("Rejected")
      expect(rows[0]["Decision date"]).to eql("20/01/2026")
      expect(rows[0]["Decision agent"]).to eql("Aaron Admin")
      expect(rows[0]["Failure reasons"]).to eql("performance_measures,disciplinary_action")
      expect(rows[0]["Not started qualification reasons"]).to eql("[]")
      expect(rows[0]["Not started qualification other reason"]).to eql(nil)
    end
  end
end
