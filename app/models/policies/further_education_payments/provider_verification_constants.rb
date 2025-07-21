module Policies
  module FurtherEducationPayments
    module ProviderVerificationConstants
      # Verification status values
      STATUS_NOT_STARTED = "not_started".freeze
      STATUS_IN_PROGRESS = "in_progress".freeze
      STATUS_COMPLETED = "completed".freeze

      # Processed by values
      PROCESSED_BY_NOT_PROCESSED = "Not processed".freeze
      PROCESSED_BY_UNASSIGNED = "Unassigned".freeze

      VERIFICATION_STATUSES = [
        STATUS_NOT_STARTED,
        STATUS_IN_PROGRESS,
        STATUS_COMPLETED
      ].freeze
    end
  end
end
