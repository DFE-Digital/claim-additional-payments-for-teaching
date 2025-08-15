module Policies
  module EarlyYearsPayments
    include BasePolicy
    extend self

    ELIGIBLE_START_DATE = Date.new(2025, 7, 15)
    RETENTION_PERIOD = 6.months

    # Percentage of approved claims to QA
    APPROVED_MIN_QA_THRESHOLD = 10
    # Percentage of rejected claims to QA
    REJECTED_MIN_QA_THRESHOLD = 10

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
      :dqt_teacher_status,
      :provider_email_address,
      :practitioner_first_name,
      :practitioner_surname
    ]

    # Attributes to retain on submitted claims until EXTENDED_PERIOD_END_DATE
    PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD = []

    # Claims from before this date will have their retained attributes deleted
    # NOOP as PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD is empty
    EXTENDED_PERIOD_END_DATE = ->(start_of_academic_year) {}

    # Options shown to admins when rejecting a claim
    ADMIN_DECISION_REJECTED_REASONS = [
      :claim_cancelled_by_employer,
      :identity_check_failed,
      :six_month_retention_check_failed,
      :duplicate,
      :no_response,
      :other
    ]

    def notify_reply_to_id
      "581f1cd6-3351-4fd6-b408-e53ce8d86a28"
    end

    def award_amount
      1_000
    end

    def auto_check_student_loan_plan_task?
      true
    end

    def approvable?(claim)
      claim.tasks.find_or_initialize_by(name: "employment").passed?
    end

    def decision_deadline_date(claim)
      claim.eligibility.start_date + RETENTION_PERIOD
    end

    def mailer
      EarlyYearsPaymentsMailer
    end

    def task_available?(task)
      case task.name
      when "employment"
        task.claim.eligibility.employment_task_available?
      else
        task.claim.eligibility.practitioner_journey_completed?
      end
    end

    def require_in_progress_update_emails?
      false
    end

    def payroll_file_name
      "EYFinancialIncentive"
    end
  end
end
