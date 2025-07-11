module Policies
  module InternationalRelocationPayments
    include BasePolicy
    extend self

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::FraudRisk,
      AutomatedChecks::ClaimVerifiers::PreviousYearClaims
    ].freeze

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["passport_number"]].freeze

    # Percentage of approved claims to QA
    APPROVED_MIN_QA_THRESHOLD = 100
    # Percentage of rejected claims to QA
    REJECTED_MIN_QA_THRESHOLD = 10

    # Options shown to admins when rejecting a claim
    ADMIN_DECISION_REJECTED_REASONS = [
      :duplicate,
      :previous_payment_not_received,
      :one_non_statutory_break,
      :ineligible_visa,
      :ineligible_school,
      :invalid_bank_details,
      :ineligible_employment_terms,
      :no_response_from_school,
      :suspected_fraud,
      :information_mismatch_new_details_needed
    ]

    # Attributes to delete from claims submitted before the current academic
    # year
    PERSONAL_DATA_ATTRIBUTES_TO_DELETE = [
      :date_of_birth,
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :address_line_4,
      :postcode,
      :payroll_gender,
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
    PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD = [
      :first_name,
      :middle_name,
      :surname,
      :national_insurance_number,
      :passport_number
    ]

    # Claims from before this date will have their retained attributes deleted
    EXTENDED_PERIOD_END_DATE = ->(start_of_academic_year) do
      start_of_academic_year - 2.years
    end

    def notify_reply_to_id
      "b11c0da5-f976-4cc2-8464-23e4dda63fc4"
    end

    def award_amount
      5_000
    end

    def payroll_file_name
      "IRP"
    end
  end
end
