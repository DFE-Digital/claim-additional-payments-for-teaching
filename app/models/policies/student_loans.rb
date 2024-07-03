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
    #  - checking payments with multiple policies: ClaimsPreventingPaymentFinder
    #  - matching claims with multiple policies: MatchingAttributeFinder
    OTHER_CLAIMABLE_POLICIES = [
      EarlyCareerPayments,
      LevellingUpPremiumPayments
    ]

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["teacher_reference_number"]].freeze

    SEARCHABLE_ELIGIBILITY_ATTRIBUTES = %w[teacher_reference_number].freeze

    # Percentage of claims to QA
    MIN_QA_THRESHOLD = 10

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

      if format == :short
        "#{start_year}/#{end_year}"
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
