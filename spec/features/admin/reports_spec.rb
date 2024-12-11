require "rails_helper"

RSpec.describe "Admin reports" do
  around do |example|
    travel_to Date.new(2024, 12, 6) do
      example.run
    end
  end

  describe "Approved FE claims with failing provider verification" do
    it "returns a CSV report" do
      claim = create(
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
        claim: claim
      )

      sign_in_as_service_operator

      visit admin_claims_path

      click_on "Reports"

      click_on(
        "FE TRI approved claims whereby the provider check status is 'failed'"
      )

      csv_data = page.body

      csv = CSV.parse(csv_data, headers: true)
      row = csv.first

      expect(row.fetch("Claim reference")).to eq(claim.reference)
      expect(row.fetch("Full name")).to eq("Elizabeth Hoover")
      expect(row.fetch("Claim amount")).to eq("£2,000")
      expect(row.fetch("Claim status")).to eq("Approved awaiting QA")
      expect(row.fetch("Decision date")).to eq("06/12/2024")
      expect(row.fetch("Decision agent")).to eq("Aaron Admin")
      expect(row.fetch("Contract of employment")).to eq("Yes")
      expect(row.fetch("Teaching responsibilities")).to eq("Yes")
      expect(row.fetch("First 5 years of teaching")).to eq("Yes")
      expect(row.fetch("One full term")).to eq("N/A")
      expect(row.fetch("Timetabled teaching hours")).to eq("Yes")
      expect(row.fetch("Age range taught")).to eq("No")
      expect(row.fetch("Subject")).to eq("No")
      expect(row.fetch("Course")).to eq("??")
      expect(row.fetch("2.5 hours weekly teaching")).to eq("N/A")
      expect(row.fetch("Performance")).to eq("Yes")
      expect(row.fetch("Disciplinary")).to eq("Yes")
    end
  end

  describe "Approved claims failing qualification task" do
    it "returns a CSV report" do
      claim = create(
        :claim,
        :with_dqt_teacher_status,
        :approved,
        policy: Policies::LevellingUpPremiumPayments,
        first_name: "Elizabeth",
        surname: "Hoover",
        eligibility_attributes: {
          teacher_reference_number: "1234567",
          qualification: :postgraduate_itt,
          itt_academic_year: "2023/2024",
          eligible_itt_subject: :mathematics
        },
        dqt_teacher_status: {
          initial_teacher_training: {
            programme_start_date: "2022-09-01",
            subject1: "mathematics",
            subject1_code: "G100",
            qualification: "BA (Hons)"
          },
          qualified_teacher_status: {
            qts_date: "2022-12-01"
          }
        }
      )

      create(
        :task,
        :failed,
        name: "qualifications",
        claim: claim
      )

      sign_in_as_service_operator

      visit admin_claims_path

      click_on "Reports"

      click_on "Approved claims failing qualification task"

      csv_data = page.body

      csv = CSV.parse(csv_data, headers: true)
      row = csv.first

      expect(row.fetch("Claim reference")).to eq(claim.reference)
      expect(row.fetch("Teacher reference number")).to eq("1234567")
      expect(row.fetch("Policy")).to eq("STRI")
      expect(row.fetch("Status")).to eq("Approved awaiting payroll")
      expect(row.fetch("Decision date")).to eq("06/12/2024")
      expect(row.fetch("Decision agent")).to eq("Aaron Admin")
      expect(row.fetch("Qualification")).to eq("postgraduate_itt")
      expect(row.fetch("ITT start year")).to eq("2023/2024")
      expect(row.fetch("ITT subject")).to eq("mathematics")
      expect(row.fetch("ITT subjects")).to eq("mathematics")
      expect(row.fetch("ITT start date")).to eq("01/09/2022")
      expect(row.fetch("QTS award date")).to eq("01/12/2022")
      expect(row.fetch("Qualification name")).to eq("BA (Hons)")
    end
  end

  describe "Duplicate claims" do
    it "returns a CSV report" do
      claim_1 = create(
        :claim,
        :current_academic_year,
        :approved,
        email_address: "test@example.com",
        policy: Policies::InternationalRelocationPayments,
        eligibility_attributes: {
          award_amount: 2_000
        }
      )

      claim_2 = create(
        :claim,
        :current_academic_year,
        :approved,
        email_address: "test@example.com",
        policy: Policies::InternationalRelocationPayments,
        eligibility_attributes: {
          award_amount: 2_000
        }
      )

      sign_in_as_service_operator

      visit admin_claims_path

      click_on "Reports"

      click_on "Duplicate claims"

      csv_data = page.body

      csv = CSV.parse(csv_data, headers: true)

      claim_references = csv.map { |row| row.fetch("Claim reference") }

      expect(claim_references).to match_array([
        claim_1.reference,
        claim_2.reference
      ])
    end
  end
end
