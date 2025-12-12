module Policies
  module FurtherEducationPayments
    DECISION_DEADLINE = 25.weeks.freeze
    # How long after claim submission the provider has to complete
    # verification before it is considered overdue
    POST_SUBMISSION_VERIFICATION_DEADLINE = 2.weeks

    include BasePolicy
    extend self

    CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_claim_verifier"

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["teacher_reference_number"]].freeze

    # Percentage of approved claims to QA
    APPROVED_MIN_QA_THRESHOLD = 10
    # Percentage of rejected claims to QA
    REJECTED_MIN_QA_THRESHOLD = 10

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::OneLoginIdentity,
      AutomatedChecks::ClaimVerifiers::Employment,
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan,
      AutomatedChecks::ClaimVerifiers::FraudRisk,
      AutomatedChecks::ClaimVerifiers::FeRepeatApplicantCheck
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
      :information_mismatch_against_year_1_application,
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

    def alternative_idv_completed!(claim)
      Tasks::FeAlternativeVerificationJob.perform_later(claim)
    end

    def provider_verification_completed!(claim)
      Tasks::FeProviderVerificationV2Job.perform_later(claim)
    end

    def notify_reply_to_id
      "89939786-7078-4267-b197-ee505dfad8ae"
    end

    def verification_due_date_for_claim(claim)
      (claim.created_at + POST_SUBMISSION_VERIFICATION_DEADLINE).to_date
    end

    def verification_expiry_date_for_claim(claim)
      verification_due_date_for_claim(claim) + 3.weeks
    end

    def verification_chase_due_date_for_claim(claim)
      (claim.eligibility.provider_verification_email_last_sent_at + 2.weeks).to_date
    end

    def verification_overdue?(claim)
      verification_due_date_for_claim(claim) < Time.zone.today
    end

    def duplicate_claim?(claim)
      Claim::MatchingAttributeFinder.new(claim).matching_claims.exists?
    end

    def teaching_start_year_mismatch?(claim)
      previous_approved_claim = claim.eligibility.previous_approved_claim

      return false if previous_approved_claim.nil?

      if year_2_claim?(claim)
        previous_approved_claim.eligibility.further_education_teaching_start_year == "2020"
      else
        previous_approved_claim.eligibility.further_education_teaching_start_year !=
          claim.eligibility.further_education_teaching_start_year
      end
    end

    def previous_claim_rejected_due_to_start_year_mismatch?(claim)
      eligibility = claim.eligibility
      previous_claim_year = eligibility.previous_claim_year

      return false if eligibility.approved_claims_for_academic_year(previous_claim_year).exists?

      eligibility.rejected_claims_for_academic_year_with_start_year_matches_claim_false(
        previous_claim_year
      ).exists?
    end

    def auto_check_student_loan_plan_task?
      true
    end

    def payroll_file_name
      "FELUPEXPANSION"
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
          claim.failed_one_login_idv?
        else
          true
        end
      end
    end

    def eligibility_page_url
      "https://www.gov.uk/guidance/targeted-retention-incentive-payments-for-fe-teachers"
    end

    # given a journey session
    # does the claimant have an existing journey session in play
    # based on their one login uid
    def existing_in_progress_claim?(journey_session:)
      return if journey_session.answers.onelogin_uid.blank?

      account = OneLoginAccount.new(uid: journey_session.answers.onelogin_uid)
      journey_sessions = account.resumable_journey_sessions(journey: Journeys::FurtherEducationPayments)
      journey_sessions.count > 1
    end

    def request_service_access_url(dfe_sign_in_uid)
      [
        "https://services.signin.education.gov.uk",
        "request-service", DfeSignIn.configuration_for_client_id(ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID")).client_id,
        "users", dfe_sign_in_uid
      ].join("/")
    end

    def sign_out_url
      dfe_sign_out_redirect_uri = URI.join(ENV.fetch("DFE_SIGN_IN_ISSUER"), "/session/end")

      post_logout_redirect_uri = URI.join(ENV.fetch("DFE_SIGN_IN_REDIRECT_BASE_URL"), "/further-education-payments-provider/auth/sign-out")
      client_id = DfeSignIn.configuration_for_client_id(ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID")).client_id

      params = {
        post_logout_redirect_uri:,
        client_id:
      }

      dfe_sign_out_redirect_uri.query = URI.encode_www_form(params)
      dfe_sign_out_redirect_uri.to_s
    end

    def admin_tasks_presenter(claim)
      if year_1_claim?(claim)
        self::YearOneAdminTasksPresenter.new(claim)
      else
        self::AdminTasksPresenter.new(claim)
      end
    end

    def decision_deadline_date(claim)
      (claim.submitted_at + DECISION_DEADLINE).to_date
    end

    def year_1_claim?(claim)
      claim.academic_year == AcademicYear.new(2024)
    end

    def year_2_claim?(claim)
      claim.academic_year == AcademicYear.new(2025)
    end
  end
end
