module Policies
  module FurtherEducationPayments
    include BasePolicy
    extend self

    # Used in
    #  - matching claims with multiple policies: MatchingAttributeFinder
    OTHER_CLAIMABLE_POLICIES = [
      EarlyCareerPayments,
      StudentLoans,
      LevellingUpPremiumPayments
    ]

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["teacher_reference_number"]].freeze

    # Percentage of claims to QA
    MIN_QA_THRESHOLD = 0

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::Identity,
      AutomatedChecks::ClaimVerifiers::ProviderVerification,
      AutomatedChecks::ClaimVerifiers::Employment,
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan
    ]

    # Options shown to admins when rejecting a claim
    ADMIN_DECISION_REJECTED_REASONS = [
      :no_teaching_responsibilities,
      :no_eligible_contract_of_employment,
      :works_less_than_2_point_5_hours_per_week,
      :has_worked_in_further_education_for_more_than_5_years,
      :ineligible_subject_or_courses,
      :insufficient_time_spent_teaching_eligibble_students,
      :subject_to_performance_measures,
      :subject_to_disciplinary_action,
      :identity_check_failed,
      :duplicate_claim,
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
      "89939786-7078-4267-b197-ee505dfad8ae"
    end

    def verification_due_date_for_claim(claim)
      (claim.created_at + 3.weeks).to_date
    end

    def verification_chase_due_date_for_claim(claim)
      (claim.eligibility.provider_verification_chase_email_last_sent_at + 3.weeks).to_date
    end

    def duplicate_claim?(claim)
      Claim::MatchingAttributeFinder.new(claim).matching_claims.exists?
    end

    def auto_check_student_loan_plan_task?
      true
    end

    def payroll_file_name
      "FELUPEXPANSION"
    end
  end
end
