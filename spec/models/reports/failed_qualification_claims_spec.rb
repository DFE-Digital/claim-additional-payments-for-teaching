require "rails_helper"

RSpec.describe Reports::FailedQualificationClaims do
  around do |example|
    travel_to Date.new(2024, 11, 1) do
      example.run
    end
  end

  describe "to_csv" do
    it "returns a csv of the claims" do
      payroll_run_1 = create(
        :payroll_run,
        created_at: 1.month.ago.beginning_of_month
      )

      payroll_run_2 = create(:payroll_run)

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
      targeted_retention_incentive_claim_approved_passed_qualification_task = create(
        :claim,
        :approved,
        policy: Policies::TargetedRetentionIncentivePayments,
        academic_year: AcademicYear.new(2024)
      )

      create(
        :task,
        :passed,
        name: "qualifications",
        claim: targeted_retention_incentive_claim_approved_passed_qualification_task
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
        }
      )

      create(
        :task,
        :failed,
        name: "qualifications",
        claim: ecp_claim_approved_failed_qualification_task
      )

      create(
        :note,
        label: "qualifications",
        claim: ecp_claim_approved_failed_qualification_task,
        body: <<~HTML
          [DQT Qualification] - Ineligible:
          <pre>
            ITT subjects: mathematics, physics
            ITT subject codes:  100403, F300
            Degree codes:       456
            ITT start date:     01/08/2022
            QTS award date:     01/09/2023
            Qualification name: Core
          </pre>
        HTML
      )

      # included
      targeted_retention_incentive_claim_approved_failed_qualification_task = create(
        :claim,
        :approved,
        policy: Policies::TargetedRetentionIncentivePayments,
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
        }
      )

      payment_1 = create(
        :payment,
        claims: [targeted_retention_incentive_claim_approved_failed_qualification_task],
        payroll_run: payroll_run_1
      )

      create(
        :task,
        :failed,
        name: "qualifications",
        claim: targeted_retention_incentive_claim_approved_failed_qualification_task
      )

      create(
        :note,
        label: "qualifications",
        claim: targeted_retention_incentive_claim_approved_failed_qualification_task,
        body: <<~HTML
          [DQT Qualification] - Ineligible:
          <pre>
            ITT subjects: physics
            ITT subject codes:  F300
            Degree codes:       456
            ITT start date:     02/08/2022
            QTS award date:     01/10/2023
            Qualification name: Core
          </pre>
        HTML
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
        }
      )

      create(
        :task,
        :failed,
        name: "qualifications",
        claim: tslr_claim_approved_failed_qualification_task
      )

      create(
        :note,
        label: "qualifications",
        claim: tslr_claim_approved_failed_qualification_task,
        body: <<~HTML
          [DQT Qualification] - Ineligible:
          <pre>
            ITT subjects: physics
            ITT subject codes:  F300
            Degree codes:       456
            ITT start date:     02/08/2022
            QTS award date:     01/10/2023
            Qualification name: Core
          </pre>
        HTML
      )

      # included "no match" on the task
      ecp_claim_approved_no_match_qualification_task = create(
        :claim,
        :approved,
        policy: Policies::EarlyCareerPayments,
        academic_year: AcademicYear.new(2024),
        decision_creator: create(
          :dfe_signin_user,
          given_name: "Some",
          family_name: "admin"
        ),
        eligibility_attributes: {
          teacher_reference_number: "4444444",
          eligible_itt_subject: :mathematics,
          itt_academic_year: AcademicYear.new(2021),
          qualification: :postgraduate_itt
        }
      )

      create(
        :task,
        :claim_verifier_context,
        claim_verifier_match: :none,
        passed: nil,
        name: "qualifications",
        claim: ecp_claim_approved_no_match_qualification_task
      )

      create(
        :note,
        label: "qualifications",
        claim: ecp_claim_approved_no_match_qualification_task,
        body: <<~HTML
          [DQT Qualification] - Ineligible:
          <pre>
            ITT subjects: mathematics, physics
            ITT subject codes:  100403, F300
            Degree codes:       456
            ITT start date:     01/08/2022
            QTS award date:     01/09/2023
            Qualification name: Core
          </pre>
        HTML
      )

      # included "Ineligible" DQT status - task passed
      ecp_claim_approved_ineligibile_note = create(
        :claim,
        :approved,
        policy: Policies::EarlyCareerPayments,
        academic_year: AcademicYear.new(2024),
        decision_creator: create(
          :dfe_signin_user,
          given_name: "Some",
          family_name: "admin"
        ),
        eligibility_attributes: {
          teacher_reference_number: "5555555",
          eligible_itt_subject: :mathematics,
          itt_academic_year: AcademicYear.new(2021),
          qualification: :postgraduate_itt
        }
      )

      create(
        :task,
        claim_verifier_match: :none,
        passed: true,
        name: "qualifications",
        claim: ecp_claim_approved_ineligibile_note
      )

      create(
        :note,
        label: "qualifications",
        claim: ecp_claim_approved_ineligibile_note,
        body: <<~HTML
          [DQT Qualification] - Ineligible:
          <pre>
            ITT subjects: mathematics, physics
            ITT subject codes:  100403, F300
            Degree codes:       456
            ITT start date:     01/08/2022
            QTS award date:     01/09/2023
            Qualification name: Core
          </pre>
        HTML
      )

      payment_2 = create(
        :payment,
        claims: [ecp_claim_approved_ineligibile_note],
        payroll_run: payroll_run_1
      )

      # included "Not eligible" DQT status - task passed
      ecp_claim_approved_not_eligible_note = create(
        :claim,
        :approved,
        policy: Policies::EarlyCareerPayments,
        academic_year: AcademicYear.new(2024),
        decision_creator: create(
          :dfe_signin_user,
          given_name: "Some",
          family_name: "admin"
        ),
        eligibility_attributes: {
          teacher_reference_number: "6666666",
          eligible_itt_subject: :mathematics,
          itt_academic_year: AcademicYear.new(2021),
          qualification: :postgraduate_itt
        }
      )

      create(
        :task,
        claim_verifier_match: :none,
        passed: true,
        name: "qualifications",
        claim: ecp_claim_approved_not_eligible_note
      )

      create(
        :note,
        label: "qualifications",
        claim: ecp_claim_approved_not_eligible_note,
        body: "[DQT Qualification] - Not eligible"
      )

      payment_3 = create(
        :payment,
        claims: [ecp_claim_approved_not_eligible_note],
        payroll_run: payroll_run_1
      )

      payment_4 = create(
        :payment,
        claims: [ecp_claim_approved_not_eligible_note],
        payroll_run: payroll_run_2
      )

      csv = CSV.parse(described_class.new.to_csv, headers: true)

      expect(csv.to_a).to match_array([
        [
          "Claim reference",
          "Teacher reference number",
          "Policy",
          "Status",
          "payment_id",
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
          nil,
          "01/11/2024",
          "Some admin",
          "postgraduate_itt",
          "2021/2022",
          "mathematics",
          "mathematics, physics",
          "01/08/2022",
          "01/09/2023",
          "Core"
        ],
        [
          targeted_retention_incentive_claim_approved_failed_qualification_task.reference,
          "2222222",
          "STRI",
          "Payrolled",
          payment_1.id,
          "01/11/2024",
          "Some admin",
          "postgraduate_itt",
          "2021/2022",
          "physics",
          "physics",
          "02/08/2022",
          "01/10/2023",
          "Core"
        ],
        [
          tslr_claim_approved_failed_qualification_task.reference,
          "3333333",
          "TSLR",
          "Approved awaiting payroll",
          nil,
          "01/11/2024",
          "Some admin",
          nil,
          nil,
          nil,
          "physics",
          "02/08/2022",
          "01/10/2023",
          "Core"
        ],
        [
          ecp_claim_approved_no_match_qualification_task.reference,
          "4444444",
          "ECP",
          "Approved awaiting payroll",
          nil,
          "01/11/2024",
          "Some admin",
          "postgraduate_itt",
          "2021/2022",
          "mathematics",
          "mathematics, physics",
          "01/08/2022",
          "01/09/2023",
          "Core"
        ],
        [
          ecp_claim_approved_ineligibile_note.reference,
          "5555555",
          "ECP",
          "Payrolled",
          payment_2.id,
          "01/11/2024",
          "Some admin",
          "postgraduate_itt",
          "2021/2022",
          "mathematics",
          "mathematics, physics",
          "01/08/2022",
          "01/09/2023",
          "Core"
        ],
        [
          ecp_claim_approved_not_eligible_note.reference,
          "6666666",
          "ECP",
          "Payrolled",
          "#{payment_3.id};#{payment_4.id}",
          "01/11/2024",
          "Some admin",
          "postgraduate_itt",
          "2021/2022",
          "mathematics",
          nil,
          nil,
          nil,
          nil
        ]
      ])
    end
  end
end
