module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class Session < Journeys::Session
      # dependent: :purge_later by default
      # — blobs are deleted from Azure asynchronously when the session is destroyed
      has_many_attached :employment_proofs
    end
  end
end
