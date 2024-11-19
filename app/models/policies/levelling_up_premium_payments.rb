module Policies
  module LevellingUpPremiumPayments
    include BasePolicy

    extend self

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::Identity,
      AutomatedChecks::ClaimVerifiers::Qualifications,
      AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
      AutomatedChecks::ClaimVerifiers::Employment,
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan,
      AutomatedChecks::ClaimVerifiers::FraudRisk
    ].freeze

    # Used in
    #  - matching claims with multiple policies: MatchingAttributeFinder
    OTHER_CLAIMABLE_POLICIES = [
      EarlyCareerPayments,
      StudentLoans,
      FurtherEducationPayments,
      EarlyYearsPayments
    ].freeze

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["teacher_reference_number"]].freeze

    SEARCHABLE_ELIGIBILITY_ATTRIBUTES = %w[teacher_reference_number].freeze

    POLICY_START_YEAR = AcademicYear.new(2022).freeze
    POLICY_END_YEAR = AcademicYear.new(2025).freeze

    # Percentage of claims to QA
    MIN_QA_THRESHOLD = 10

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

    def current_subject_symbols(claim_year:, itt_year:)
      subject_symbols(claim_year: claim_year, itt_year: itt_year)
    end

    def future_subject_symbols(claim_year:, itt_year:)
      future_years(claim_year).flat_map do |year|
        subject_symbols(claim_year: year, itt_year: itt_year)
      end
    end

    def current_and_future_subject_symbols(claim_year:, itt_year:)
      [
        *current_subject_symbols(
          claim_year: claim_year,
          itt_year: itt_year
        ),
        *future_subject_symbols(
          claim_year: claim_year,
          itt_year: itt_year
        )
      ].uniq
    end

    # Ideally we wouldn't have this method at all. Unfortunately it was hardcoded like
    # this before we realised trainee teachers weren't as special a case as we
    # thought.
    def fixed_subject_symbols
      [:chemistry, :computing, :mathematics, :physics]
    end

    def subject_symbols(claim_year:, itt_year:)
      return [] unless (POLICY_START_YEAR..POLICY_END_YEAR).cover?(claim_year)

      previous_five_years = (claim_year - 5)...claim_year

      if previous_five_years.cover?(itt_year)
        fixed_subject_symbols
      else
        []
      end
    end

    def current_and_future_years(year)
      fail "year before policy start year" if year < POLICY_START_YEAR

      [year] + future_years(year)
    end

    def future_years(year)
      fail "year before policy start year" if year < POLICY_START_YEAR

      year + 1..POLICY_END_YEAR
    end

    def selectable_itt_years_for_claim_year(claim_year)
      (AcademicYear.new(claim_year - 5)...AcademicYear.new(claim_year)).to_a
    end
  end
end
