require "rails_helper"

RSpec.describe Admin::Reports::FeApprovedClaimsWithFailingProviderVerification do
  around do |example|
    travel_to Date.new(2024, 11, 1) do
      example.run
    end
  end

  describe "#to_csv" do
    it "returns a csv of approved fe claims with failing provider verification" do
      fe_claim_with_passing_provider_check = create(
        :claim,
        :approved,
        policy: Policies::FurtherEducationPayments
      )

      create(
        :task,
        :passed,
        name: "provider_verification",
        claim: fe_claim_with_passing_provider_check
      )

      fe_fixed_claim_with_failing_provider_check = create(
        :claim,
        :approved,
        policy: Policies::FurtherEducationPayments,
        first_name: "Elizabeth",
        surname: "Hoover",
        qa_required: true,
        eligibility_attributes: {
          award_amount: 2_000,
          contract_type: "permanent",
          verification: {
            assertions: [
              {
                name: "contract_type",
                outcome: true
              },
              {
                name: "teaching_responsibilities",
                outcome: true
              },
              {
                name: "further_education_teaching_start_year",
                outcome: true
              },
              {
                name: "teaching_hours_per_week",
                outcome: true
              },
              {
                name: "half_teaching_hours",
                outcome: false
              },
              {
                name: "subjects_taught",
                outcome: false
              },
              {
                name: "subject_to_formal_performance_action",
                outcome: true
              },
              {
                name: "subject_to_disciplinary_action",
                outcome: true
              }
            ]
          }
        }
      )

      create(
        :task,
        :failed,
        name: "provider_verification",
        claim: fe_fixed_claim_with_failing_provider_check
      )

      fe_variable_claim_with_failing_provider_check = create(
        :claim,
        :approved,
        policy: Policies::FurtherEducationPayments,
        first_name: "Edna",
        surname: "Krabappel",
        eligibility_attributes: {
          award_amount: 3_000,
          contract_type: "variable_hours",
          verification: {
            assertions: [
              {
                name: "contract_type",
                outcome: true
              },
              {
                name: "teaching_responsibilities",
                outcome: true
              },
              {
                name: "further_education_teaching_start_year",
                outcome: true
              },
              {
                name: "taught_at_least_one_term",
                outcome: true
              },
              {
                name: "teaching_hours_per_week",
                outcome: true
              },
              {
                name: "half_teaching_hours",
                outcome: true
              },
              {
                name: "subjects_taught",
                outcome: true
              },
              {
                name: "teaching_hours_per_week_next_term",
                outcome: true
              },
              {
                name: "subject_to_formal_performance_action",
                outcome: true
              },
              {
                name: "subject_to_disciplinary_action",
                outcome: false
              }
            ]
          }
        }
      )

      create(
        :task,
        :failed,
        name: "provider_verification",
        claim: fe_variable_claim_with_failing_provider_check
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
          "Contract of employment",
          "Teaching responsibilities",
          "First 5 years of teaching",
          "One full term",
          "Timetabled teaching hours",
          "Age range taught",
          "Subject",
          "Course",
          "2.5 hours weekly teaching",
          "Performance",
          "Disciplinary"
        ],
        [
          fe_fixed_claim_with_failing_provider_check.reference,
          "Elizabeth Hoover",
          "£2,000",
          "Approved awaiting QA",
          "01/11/2024",
          "Aaron Admin",
          "Yes", # contract of employment
          "Yes", # teaching responsibilities
          "Yes", # first 5 years of teaching
          "N/A", # one full term - not a question for fixed term contracts
          "Yes", # timetabled teaching hours
          "No", # age range taught
          "No", # subject
          "??", # course
          "N/A", # 2.5 hours weekly teaching
          "Yes", # performance
          "Yes" # disciplinary
        ],
        [
          fe_variable_claim_with_failing_provider_check.reference,
          "Edna Krabappel",
          "£3,000",
          "Approved awaiting payroll",
          "01/11/2024",
          "Aaron Admin",
          "Yes", # contract of employment
          "Yes", # teaching responsibilities
          "Yes", # first 5 years of teaching
          "Yes", # one full term
          "Yes", # timetabled teaching hours
          "Yes", # age range taught
          "Yes", # subject
          "??", # course
          "Yes", # 2.5 hours weekly teaching
          "Yes", # performance
          "No" # disciplinary
        ]
      ])
    end
  end
end
