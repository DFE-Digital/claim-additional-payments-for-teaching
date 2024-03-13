module Policies
  module LevellingUpPremiumPayments
    include BasePolicy

    extend self

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::Identity,
      AutomatedChecks::ClaimVerifiers::Qualifications,
      AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
      AutomatedChecks::ClaimVerifiers::Employment
    ].freeze

    def notify_reply_to_id
      "03ece7eb-2a5b-461b-9c91-6630d0051aa6"
    end

    def eligibility_page_url
      "https://www.gov.uk/guidance/levelling-up-premium-payments-for-teachers"
    end

    def eligibility_criteria_url
      eligibility_page_url + "#eligibility-criteria-for-teachers"
    end
  end
end
