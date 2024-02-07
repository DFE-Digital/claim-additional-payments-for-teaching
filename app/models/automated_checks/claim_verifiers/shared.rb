# frozen_string_literal: true

module AutomatedChecks
  module ClaimVerifiers
    module Shared
      VERIFIERS = [
        AutomatedChecks::ClaimVerifiers::Identity,
        AutomatedChecks::ClaimVerifiers::Qualifications,
        AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
        AutomatedChecks::ClaimVerifiers::Employment
      ].freeze
    end
  end
end
