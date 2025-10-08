require "rails_helper"

RSpec.describe Reports::FailedProviderCheckClaims do
  around do |example|
    travel_to Date.new(2025, 11, 1) do
      example.run
    end
  end

  describe "#to_csv" do
    it "returns a csv of approved fe claims with failing provider verification" do
      fe_claim_with_failing_provider_check_1 = create(
        :claim,
        :approved,
        policy: Policies::FurtherEducationPayments,
        first_name: "Elizabeth",
        surname: "Hoover",
        qa_required: true,
        eligibility_attributes: {
          award_amount: 2_000,
          provider_verification_teaching_responsibilities: false
        }
      )

      create(
        :task,
        :failed,
        name: "fe_provider_verification_v2",
        claim: fe_claim_with_failing_provider_check_1
      )

      fe_claim_with_failing_provider_check_2 = create(
        :claim,
        :approved,
        policy: Policies::FurtherEducationPayments,
        first_name: "Edna",
        surname: "Krabappel",
        eligibility_attributes: {
          award_amount: 3_000,
          provider_verification_contract_type: "variable_hours",
          provider_verification_teaching_responsibilities: true,
          provider_verification_teaching_start_year_matches_claim: true,
          provider_verification_taught_at_least_one_academic_term: true,
          provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week",
          provider_verification_half_teaching_hours: true,
          provider_verification_half_timetabled_teaching_time: true,
          provider_verification_not_started_qualification_reasons: ["no_valid_reason"],
          provider_verification_continued_employment: true,
          provider_verification_performance_measures: false,
          provider_verification_disciplinary_action: false
        }
      )

      create(
        :task,
        :failed,
        name: "fe_provider_verification_v2",
        claim: fe_claim_with_failing_provider_check_2
      )

      _fe_claim_with_passing_provider_check = create(
        :claim,
        :approved,
        policy: Policies::FurtherEducationPayments,
        first_name: "Edna",
        surname: "Krabappel",
        eligibility_attributes: {
          award_amount: 3_000,
          provider_verification_contract_type: "variable_hours",
          provider_verification_teaching_responsibilities: true,
          provider_verification_teaching_start_year_matches_claim: true,
          provider_verification_taught_at_least_one_academic_term: true,
          provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week",
          provider_verification_half_teaching_hours: true,
          provider_verification_half_timetabled_teaching_time: true,
          provider_verification_continued_employment: true,
          provider_verification_performance_measures: false,
          provider_verification_disciplinary_action: false
        }
      )

      csv = CSV.parse(described_class.new.to_csv, headers: true)

      expect(csv.to_a).to match_array([
        [
          "Claim reference",
          "Full name",
          "Claim amount",
          "Claim status",
          "Decision date",
          "Decision agent",
          "Teaching responsibilities",
          "Contract of employment",
          "First 5 years of teaching",
          "One full term",
          "Timetabled teaching hours",
          "Age range taught",
          "Subject",
          "Course",
          "Continued employment",
          "Performance",
          "Disciplinary"
        ],
        [
          fe_claim_with_failing_provider_check_1.reference,
          "Elizabeth Hoover",
          "£2,000",
          "Approved awaiting QA",
          "01/11/2025",
          "Aaron Admin",
          "No",
          "N/A",
          "N/A",
          "N/A",
          "N/A",
          "N/A",
          "N/A",
          "N/A",
          "N/A",
          "N/A",
          "N/A"
        ],
        [
          fe_claim_with_failing_provider_check_2.reference,
          "Edna Krabappel",
          "£3,000",
          "Approved awaiting payroll",
          "01/11/2025",
          "Aaron Admin",
          "Yes",
          "variable_hours",
          "Yes",
          "Yes",
          "20_or_more_hours_per_week",
          "Yes",
          "Yes",
          "Yes",
          "Yes",
          "No",
          "No"
        ]
      ])
    end
  end
end
