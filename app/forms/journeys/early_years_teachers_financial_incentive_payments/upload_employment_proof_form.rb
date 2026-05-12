# frozen_string_literal: true

module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class UploadEmploymentProofForm < Form
      attribute :file

      validates :file, presence: {message: "Select a file to upload"}

      def save
        return false if invalid?

        journey_session.employment_proofs.attach(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type,
          key: "#{journey_session.id}/employment_proof/#{SecureRandom.base58(24)}"
        )

        true
      end

      def completed?
        journey_session.employment_proofs.attached?
      end

      def has_confirmed_blobs?
        journey_session.answers.confirmed_employment_proof_blob_ids.any?
      end
    end
  end
end
