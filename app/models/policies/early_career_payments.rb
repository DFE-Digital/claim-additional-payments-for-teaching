# frozen_string_literal: true

# Module namespace specific to the policy for claiming early-career payments.
#
# Early-career payments are available to teachers starting their initial teacher training (ITT)
# in the Academic Years 2018 to 2019, 2019 to 2020 or 2020 to 2021 academic year.
# This is in addition to receiving a bursary or scholarship during ITT.
# Full details of the eligibility criteria can be found at the URL
# defined by `Policies::EarlyCareerPayments.eligibility_page_url`.
module Policies
  module EarlyCareerPayments
    include BasePolicy

    extend self

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::Identity,
      AutomatedChecks::ClaimVerifiers::Qualifications,
      AutomatedChecks::ClaimVerifiers::Induction,
      AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
      AutomatedChecks::ClaimVerifiers::Employment,
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan,
      AutomatedChecks::ClaimVerifiers::FraudRisk
    ].freeze

    POLICY_START_YEAR = AcademicYear.new(2021).freeze
    POLICY_END_YEAR = AcademicYear.new(2024).freeze

    # Used in
    #  - matching claims with multiple policies: MatchingAttributeFinder
    OTHER_CLAIMABLE_POLICIES = [
      LevellingUpPremiumPayments,
      StudentLoans,
      FurtherEducationPayments,
      EarlyYearsPayments
    ].freeze

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["teacher_reference_number"]].freeze

    SEARCHABLE_ELIGIBILITY_ATTRIBUTES = %w[teacher_reference_number].freeze

    # Percentage of claims to QA
    MIN_QA_THRESHOLD = 10

    # Options shown to admins when rejecting a claim
    ADMIN_DECISION_REJECTED_REASONS = [
      :ineligible_subject,
      :ineligible_year,
      :ineligible_school,
      :ineligible_qualification,
      :induction,
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

    def eligibility_page_url
      "https://www.gov.uk/guidance/early-career-payments-guidance-for-teachers-and-schools"
    end

    def eligibility_criteria_url
      eligibility_page_url + "#eligibility-criteria"
    end

    def notify_reply_to_id
      "3f85a1f7-9400-4b48-9a31-eaa643d6b977"
    end

    def student_loan_balance_url
      "https://www.gov.uk/sign-in-to-manage-your-student-loan-balance"
    end

    def payment_and_deductions_info_url
      eligibility_page_url + "#paying-income-tax-and-national-insurance"
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

    def subject_symbols(claim_year:, itt_year:)
      case AcademicYear.wrap(claim_year)
      when AcademicYear.new(2022), AcademicYear.new(2024)
        case AcademicYear.wrap(itt_year)
        when AcademicYear.new(2019)
          [:mathematics]
        when AcademicYear.new(2020)
          [:chemistry, :foreign_languages, :mathematics, :physics]
        else
          []
        end
      when AcademicYear.new(2023)
        case AcademicYear.wrap(itt_year)
        when AcademicYear.new(2018)
          [:mathematics]
        when AcademicYear.new(2020)
          [:chemistry, :foreign_languages, :mathematics, :physics]
        else
          []
        end
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
  end
end
