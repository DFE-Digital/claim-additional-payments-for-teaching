module Policies
  module TargetedRetentionIncentivePayments
    include BasePolicy

    extend self

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::ClaimCheckingTasks,
      AutomatedChecks::ClaimVerifiers::Identity,
      AutomatedChecks::ClaimVerifiers::Qualifications,
      AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
      AutomatedChecks::ClaimVerifiers::Employment,
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan,
      AutomatedChecks::ClaimVerifiers::FraudRisk
    ].freeze

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["teacher_reference_number"]].freeze

    SEARCHABLE_ELIGIBILITY_ATTRIBUTES = %w[teacher_reference_number].freeze

    POLICY_START_YEAR = AcademicYear.new(2022).freeze
    POLICY_END_YEAR = AcademicYear.new(2025).freeze
    POLICY_RANGE = POLICY_START_YEAR..POLICY_END_YEAR

    # Percentage of approved claims to QA
    APPROVED_MIN_QA_THRESHOLD = 10
    # Percentage of rejected claims to QA
    REJECTED_MIN_QA_THRESHOLD = 10

    # Options shown to admins when rejecting a claim
    ADMIN_DECISION_REJECTED_REASONS = [
      :ineligible_subject,
      :ineligible_year,
      :ineligible_school,
      :ineligible_qualification,
      :no_qts_or_qtls,
      :duplicate,
      :no_response,
      :other
    ]

    # Attributes to delete from claims submitted before the current academic
    # year
    PERSONAL_DATA_ATTRIBUTES_TO_DELETE = [
      :first_name,
      :middle_name,
      :surname,
      :date_of_birth,
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :address_line_4,
      :postcode,
      :payroll_gender,
      :national_insurance_number,
      :bank_sort_code,
      :bank_account_number,
      :building_society_roll_number,
      :banking_name,
      :hmrc_bank_validation_responses,
      :mobile_number,
      :teacher_id_user_info,
      :dqt_teacher_status
    ]

    # Attributes to retain on submitted claims until EXTENDED_PERIOD_END_DATE
    PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD = []

    # Claims from before this date will have their retained attributes deleted
    # NOOP as PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD is empty
    EXTENDED_PERIOD_END_DATE = ->(start_of_academic_year) {}

    def notify_reply_to_id
      "03ece7eb-2a5b-461b-9c91-6630d0051aa6"
    end

    def eligibility_page_url
      "https://www.gov.uk/guidance/targeted-retention-incentive-payments-for-school-teachers"
    end

    def eligibility_criteria_url
      eligibility_page_url + "#eligibility-criteria"
    end

    def payment_and_deductions_info_url
      eligibility_page_url + "#payments-and-deductions"
    end

    # Agreed shorthand name to accommodate 30 character limit in payroll system (CAPT-1709)
    def payroll_file_name
      "SchoolsLUP"
    end

    def auto_check_student_loan_plan_task?
      true
    end

    def fixed_subject_symbols
      [:chemistry, :computing, :mathematics, :physics]
    end

    def selectable_itt_years_for_claim_year(claim_year)
      (AcademicYear.new(claim_year - 5)...AcademicYear.new(claim_year)).to_a
    end

    def closed?(claim_year)
      claim_year > POLICY_END_YEAR
    end

    def max_topup_amount(claim)
      Award.by_academic_year(claim.academic_year).maximum(:award_amount)
    end

    def set_a_reminder?(itt_academic_year)
      selectable_itt_years_for_claim_year(AcademicYear.next).include?(itt_academic_year)
    end

    def award_amount(school)
      return nil unless school

      school
        .targeted_retention_incentive_payments_awards
        .by_academic_year(current_academic_year)
        .first
        &.award_amount
    end
  end
end
