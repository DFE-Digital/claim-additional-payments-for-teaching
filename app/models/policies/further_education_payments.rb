module Policies
  module FurtherEducationPayments
    include BasePolicy
    extend self

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["teacher_reference_number"]].freeze

    # Percentage of approved claims to QA
    APPROVED_MIN_QA_THRESHOLD = 10
    # Percentage of rejected claims to QA
    REJECTED_MIN_QA_THRESHOLD = 10

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::OneLoginIdentity,
      AutomatedChecks::ClaimVerifiers::ProviderVerification,
      AutomatedChecks::ClaimVerifiers::AlternativeIdentityVerification,
      AutomatedChecks::ClaimVerifiers::Employment,
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan,
      AutomatedChecks::ClaimVerifiers::FraudRisk
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
      :alternative_identity_verification_check_failed,
      :duplicate_claim,
      :no_response,
      :no_response_from_employer,
      :other
    ]

    # Attributes to delete from claims submitted before the current academic
    # year
    PERSONAL_DATA_ATTRIBUTES_TO_DELETE = [
      :bank_sort_code,
      :bank_account_number,
      :building_society_roll_number,
      :banking_name,
      :teacher_id_user_info,
      :dqt_teacher_status,
      :claimant_date_of_birth,
      :claimant_postcode,
      :claimant_national_insurance_number,
      :claimant_passport_number,
      :passport_number
    ]

    # Attributes to retain on submitted claims until EXTENDED_PERIOD_END_DATE
    PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD = [
      :first_name,
      :middle_name,
      :surname,
      :date_of_birth,
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :address_line_4,
      :postcode,
      :national_insurance_number,
      :mobile_number,
      :hmrc_bank_validation_responses,
      :payroll_gender
    ]

    # Claims from before this date will have their retained attributes deleted
    EXTENDED_PERIOD_END_DATE = ->(start_of_academic_year) {
      start_of_academic_year - 5.years
    }

    def notify_reply_to_id
      "89939786-7078-4267-b197-ee505dfad8ae"
    end

    def verification_due_date_for_claim(claim)
      (claim.created_at + 2.weeks).to_date
    end

    def verification_chase_due_date_for_claim(claim)
      (claim.eligibility.provider_verification_email_last_sent_at + 2.weeks).to_date
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

    def alternative_identity_verification_required?(claim)
      return false unless FeatureFlag.enabled?(:fe_provider_identity_verification)

      claim.failed_one_login_idv?
    end

    def approvable?(claim)
      ClaimCheckingTasks.new(claim).incomplete_task_names.exclude?(
        "alternative_identity_verification"
      ) && !claim.tasks.find_by(name: "alternative_identity_verification")&.failed?
    end

    def rejectable?(claim)
      ClaimCheckingTasks.new(claim).incomplete_task_names.exclude?(
        "alternative_identity_verification"
      )
    end

    def rejected_reasons(claim)
      ADMIN_DECISION_REJECTED_REASONS.select do |reason|
        case reason
        when :alternative_identity_verification_check_failed
          alternative_identity_verification_required?(claim)
        else
          true
        end
      end
    end

    def eligibility_page_url
      "https://www.gov.uk/guidance/targeted-retention-incentive-payments-for-fe-teachers"
    end
  end
end
