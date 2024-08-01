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
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan
    ].freeze

    POLICY_START_YEAR = AcademicYear.new(2021).freeze
    POLICY_END_YEAR = AcademicYear.new(2024).freeze

    # Used in
    #  - checking payments with multiple policies: ClaimsPreventingPaymentFinder
    #  - matching claims with multiple policies: MatchingAttributeFinder
    OTHER_CLAIMABLE_POLICIES = [
      LevellingUpPremiumPayments,
      StudentLoans
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
  end
end
