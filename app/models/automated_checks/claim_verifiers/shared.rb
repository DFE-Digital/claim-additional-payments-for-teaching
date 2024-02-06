# frozen_string_literal: true

module AutomatedChecks
  module ClaimVerifiers
    module Shared
      VERIFIERS = [
        AutomatedChecks::ClaimVerifiers::Identity,
        AutomatedChecks::ClaimVerifiers::Qualifications,
        AutomatedChecks::ClaimVerifiers::Induction,
        AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
        AutomatedChecks::ClaimVerifiers::Employment,
        AutomatedChecks::ClaimVerifiers::StudentLoanAmount
      ].freeze
    end
  end
end
