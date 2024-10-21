# frozen_string_literal: true

# Module namespace specific to the policy for claiming back your student loan
# payments.
#
# This payment is available to teachers that qualified after 2013 teaching
# specific subjects in state-funded secondary schools in eligible local
# authorities. Full details of the eligibility criteria can be found at the URL
# defined by `StudentLoans.eligibility_page_url`.
module Policies
  module StudentLoans
    include BasePolicy

    extend self

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::Identity,
      AutomatedChecks::ClaimVerifiers::Qualifications,
      AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
      AutomatedChecks::ClaimVerifiers::Employment,
      AutomatedChecks::ClaimVerifiers::StudentLoanAmount
    ].freeze

    POLICY_START_YEAR = AcademicYear.new(2013).freeze
    POLICY_END_YEAR = AcademicYear.new(2020).freeze
    ACADEMIC_YEARS_QUALIFIED_TEACHERS_CAN_CLAIM_FOR = 11

    # Used in
    #  - matching claims with multiple policies: MatchingAttributeFinder
    OTHER_CLAIMABLE_POLICIES = [
      EarlyCareerPayments,
      LevellingUpPremiumPayments,
      FurtherEducationPayments
    ]

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
      :no_qts_or_qtls,
      :no_repayments_to_slc,
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
      "https://www.gov.uk/guidance/teachers-claim-back-your-student-loan-repayments"
    end

    def student_loan_balance_url
      "https://www.gov.uk/sign-in-to-manage-your-student-loan-balance"
    end

    def payment_and_deductions_info_url
      eligibility_page_url + "#payment"
    end

    def notify_reply_to_id
      "962b3044-cdd4-4dbe-b6ea-c461530b3dc6"
    end

    # Returns the AcademicYear during or after which teachers must have completed
    # their Initial Teacher Training and been awarded QTS to be eligible to make
    # a claim. Anyone qualifying before this academic year should not be able to
    # make a claim.
    #
    # Teachers that qualified after 2013 are eligible to claim back student loans
    # repayments for 10 years. Their first claim will be made in the subsequent
    # year because they are retrospectively claiming *back* repayments made during
    # the *financial year*. So for example if you qualify in 2021/2022, you are
    # eligible to claim back student loan repayments you make in the 2021/2022
    # "financial year", which ends April 2022, and the claim for that period can
    # be made from the start of the 2022/2023 "academic year".
    #
    # So to give concrete examples, teachers qualifying in 2013/2014 can make
    # claims up to 2024/2025, and a teacher qualifying in 2014/2015 can make
    # claims up to 2025/2026 and so on.
    def first_eligible_qts_award_year(claim_year = nil)
      claim_year ||= Journeys::TeacherStudentLoanReimbursement.configuration.current_academic_year
      [
        POLICY_START_YEAR,
        (claim_year - ACADEMIC_YEARS_QUALIFIED_TEACHERS_CAN_CLAIM_FOR)
      ].max
    end

    def last_eligible_qts_award_year
      POLICY_END_YEAR
    end

    # Returns human-friendly String for the financial year that Student Loans
    # claims are being made against based on the currently-configured academic
    # year for the StudentLoans policy. For example:
    #
    #   "6 April 2018 and 5 April 2019"
    def current_financial_year(format = :default)
      end_year = Journeys::TeacherStudentLoanReimbursement.configuration.current_academic_year.start_year
      start_year = end_year - 1

      case format
      when :short
        "#{start_year}/#{end_year}"
      when :to
        "6 April #{start_year} to 5 April #{end_year}"
      else
        "6 April #{start_year} and 5 April #{end_year}"
      end
    end

    # Agreed shorthand name to accommodate 30 character limit in payroll system (CAPT-1709)
    def payroll_file_name
      "TSLR"
    end
  end
end
