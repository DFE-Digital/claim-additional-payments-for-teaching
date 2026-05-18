# frozen_string_literal: true

module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class UploadEmploymentProofForm < Form
      ALLOWED_CONTENT_TYPES = %w[
        application/pdf
        image/jpeg
        image/png
        image/heic
        image/heif
      ].freeze

      MAX_FILE_SIZE = 20.megabytes

      attribute :file

      validates :file, presence: {message: "Select a file to upload"}
      validate :file_type_allowed
      validate :file_size_within_limit

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

      private

      def file_type_allowed
        return unless file.present?

        unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
          errors.add(:file, "The selected file must be a PDF, JPG, PNG or HEIC")
        end
      end

      def file_size_within_limit
        return unless file.present?

        if file.size > MAX_FILE_SIZE
          errors.add(:file, "The selected file must be smaller than 20MB")
        end
      end
    end
  end
end
