# frozen_string_literal: true

module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class InformationProvidedForm < Form
      def save
        # TODO: move job trigger to the check your answers / submission form once built
        blob_ids = journey_session.answers.confirmed_employment_proof_blob_ids

        blob_ids.each do |blob_id|
          ::EarlyYearsTeachersFinancialIncentivePayments::FetchEmploymentProofMalwareScanResultJob.perform_later(blob_id)
        end

        true
      end
    end
  end
end
