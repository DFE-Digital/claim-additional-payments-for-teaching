module Policies
  module LevellingUpPremiumPayments
    include BasePolicy

    extend self

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::Identity,
      AutomatedChecks::ClaimVerifiers::Qualifications,
      AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
      AutomatedChecks::ClaimVerifiers::Employment,
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan
    ].freeze

    # Used in
    #  - checking payments with multiple policies: ClaimsPreventingPaymentFinder
    #  - matching claims with multiple policies: MatchingAttributeFinder
    OTHER_CLAIMABLE_POLICIES = [
      EarlyCareerPayments,
      StudentLoans
    ].freeze

    ELIGIBILITY_MATCHING_ATTRIBUTES = [["teacher_reference_number"]].freeze

    SEARCHABLE_ELIGIBILITY_ATTRIBUTES = %w[teacher_reference_number].freeze

    POLICY_START_YEAR = AcademicYear.new(2022).freeze
    POLICY_END_YEAR = AcademicYear.new(2024).freeze

    def notify_reply_to_id
      "03ece7eb-2a5b-461b-9c91-6630d0051aa6"
    end

    def eligibility_page_url
      "https://www.gov.uk/guidance/levelling-up-premium-payments-for-teachers"
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
  end
end
