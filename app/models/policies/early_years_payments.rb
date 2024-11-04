module Policies
  module EarlyYearsPayments
    include BasePolicy
    extend self

    RETENTION_PERIOD = 6.months

    # Percentage of claims to QA
    MIN_QA_THRESHOLD = 10

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan,
      AutomatedChecks::ClaimVerifiers::EarlyYearsPayments::Identity
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

    # Options shown to admins when rejecting a claim
    ADMIN_DECISION_REJECTED_REASONS = [
      :claim_cancelled_by_employer,
      :six_month_retention_check_failed,
      :duplicate,
      :no_response,
      :other
    ]

    OTHER_CLAIMABLE_POLICIES = [
      EarlyCareerPayments,
      StudentLoans,
      LevellingUpPremiumPayments
    ]

    # TODO: This is needed once the reply-to email address has been added to Gov Notify
    def notify_reply_to_id
      nil
    end

    def award_amount
      1_000
    end

    def auto_check_student_loan_plan_task?
      true
    end
  end
end
