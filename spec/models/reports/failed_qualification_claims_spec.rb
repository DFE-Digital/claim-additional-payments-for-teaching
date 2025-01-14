require "rails_helper"

RSpec.describe Reports::FailedQualificationClaims do
  around do |example|
    travel_to Date.new(2024, 11, 1) do
      example.run
    end
  end

  describe "to_csv" do
    it "returns a csv of the claims" do
      # excluded, claim not approved
      ecp_claim_unapporved_failed_qualification_task = create(
        :claim,
        policy: Policies::EarlyCareerPayments,
        academic_year: AcademicYear.new(2024)
      )

      create(
        :task,
        :failed,
        name: "qualifications",
        claim: ecp_claim_unapporved_failed_qualification_task
      )

      # excluded, task passed
      lup_claim_approved_passed_qualification_task = create(
        :claim,
        :approved,
        policy: Policies::LevellingUpPremiumPayments,
        academic_year: AcademicYear.new(2024)
      )

      create(
        :task,
        :passed,
        name: "qualifications",
        claim: lup_claim_approved_passed_qualification_task
      )

      # excluded, claim not approved
      tslr_claim_rejected = create(
        :claim,
        :rejected,
        policy: Policies::StudentLoans,
        academic_year: AcademicYear.new(2024)
      )

      create(
        :task,
        :failed,
        name: "qualifications",
        claim: tslr_claim_rejected
      )

      # excluded, wrong policy!
      _fe_claim = create(
        :claim,
        :approved,
        policy: Policies::FurtherEducationPayments,
        academic_year: AcademicYear.new(2024)
      )

      # excluded, previous academic year
      ecp_claim_unapporved_failed_qualification_task = create(
        :claim,
        :approved,
        policy: Policies::EarlyCareerPayments,
        academic_year: AcademicYear.new(2023)
      )

      create(
        :task,
        :failed,
        name: "qualifications",
        claim: ecp_claim_unapporved_failed_qualification_task
      )

      # included
      ecp_claim_approved_failed_qualification_task = create(
        :claim,
        :approved,
        :flagged_for_qa,
        policy: Policies::EarlyCareerPayments,
        academic_year: AcademicYear.new(2024),
        decision_creator: create(
          :dfe_signin_user,
          given_name: "Some",
          family_name: "admin"
        ),
        eligibility_attributes: {
          teacher_reference_number: "1111111",
          eligible_itt_subject: :mathematics,
          itt_academic_year: AcademicYear.new(2021),
          qualification: :postgraduate_itt
        },
        dqt_teacher_status: {
          qualified_teacher_status: {
            qts_date: "2023-09-01",
            name: "Qualified teacher (trained)"
          },
          initial_teacher_training: {
            programme_start_date: "2022-08-01",
            subject1: "mathematics",
            subject1_code: "100403",
            subject2: "physics",
            subject3_code: "F300",
            qualification: "Graduate Diploma"
          }
        }
      )

      create(
        :task,
        :failed,
        name: "qualifications",
        claim: ecp_claim_approved_failed_qualification_task
      )

      # included
      lup_claim_approved_failed_qualification_task = create(
        :claim,
        :approved,
        policy: Policies::LevellingUpPremiumPayments,
        academic_year: AcademicYear.new(2024),
        decision_creator: create(
          :dfe_signin_user,
          given_name: "Some",
          family_name: "admin"
        ),
        eligibility_attributes: {
          teacher_reference_number: "2222222",
          eligible_itt_subject: :physics,
          itt_academic_year: AcademicYear.new(2021),
          qualification: :postgraduate_itt
        },
        dqt_teacher_status: {
          qualified_teacher_status: {
            qts_date: "2023-10-01",
            name: "Qualified teacher (trained)"
          },
          initial_teacher_training: {
            programme_start_date: "2022-08-02",
            subject1: "physics",
            subject1_code: "F300",
            qualification: "Graduate Diploma"
          }
        }
      )

      create(:payment, claims: [lup_claim_approved_failed_qualification_task])

      create(
        :task,
        :failed,
        name: "qualifications",
        claim: lup_claim_approved_failed_qualification_task
      )

      # included
      tslr_claim_approved_failed_qualification_task = create(
        :claim,
        :approved,
        policy: Policies::StudentLoans,
        academic_year: AcademicYear.new(2024),
        decision_creator: create(
          :dfe_signin_user,
          given_name: "Some",
          family_name: "admin"
        ),
        eligibility_attributes: {
          teacher_reference_number: "3333333"
        },
        dqt_teacher_status: {
          qualified_teacher_status: {
            qts_date: "2023-10-01",
            name: "Qualified teacher (trained)"
          },
          initial_teacher_training: {
            programme_start_date: "2022-08-02",
            subject1: "physics",
            subject1_code: "F300",
            qualification: "Graduate Diploma"
          }
        }
      )

      create(
        :task,
        :failed,
        name: "qualifications",
        claim: tslr_claim_approved_failed_qualification_task
      )

      csv = CSV.parse(described_class.new.to_csv, headers: true)

      expect(csv.to_a).to match_array([
        [
          "Claim reference",
          "Teacher reference number",
          "Policy",
          "Status",
          "Decision date",
          "Decision agent",
          "Applicant answers - Qualification",
          "Applicant answers - ITT start year",
          "Applicant answers - ITT subject",
          "DQT API - ITT subjects",
          "DQT API - ITT start date",
          "DQT API - QTS award date",
          "DQT API - Qualification name"
        ],
        [
          ecp_claim_approved_failed_qualification_task.reference,
          "1111111",
          "ECP",
          "Approved awaiting QA",
          "01/11/2024",
          "Some admin",
          "postgraduate_itt",
          "2021/2022",
          "mathematics",
          "mathematics, physics",
          "01/08/2022",
          "01/09/2023",
          "Graduate Diploma"
        ],
        [
          lup_claim_approved_failed_qualification_task.reference,
          "2222222",
          "STRI",
          "Payrolled",
          "01/11/2024",
          "Some admin",
          "postgraduate_itt",
          "2021/2022",
          "physics",
          "physics",
          "02/08/2022",
          "01/10/2023",
          "Graduate Diploma"
        ],
        [
          tslr_claim_approved_failed_qualification_task.reference,
          "3333333",
          "TSLR",
          "Approved awaiting payroll",
          "01/11/2024",
          "Some admin",
          nil,
          nil,
          nil,
          "physics",
          "02/08/2022",
          "01/10/2023",
          "Graduate Diploma"
        ]
      ])
    end
  end
end
