# frozen_string_literal: true

module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class ReviewEmploymentProofForm < Form
      attribute :confirmed, :string
      attribute :blob_id, :string

      validates :confirmed,
        inclusion: {
          in: %w[yes no],
          message: "Select yes if this file shows your name, your workplace and a date from the last 2 months"
        }

      def save
        return false if invalid?

        if confirmed == "no"
          journey_session.employment_proofs.purge
          journey_session.answers.confirmed_employment_proof_blob_ids.clear
          journey_session.save!
          return false
        end

        unless journey_session.answers.confirmed_employment_proof_blob_ids.include?(blob_id)
          journey_session.answers.confirmed_employment_proof_blob_ids << blob_id
          journey_session.save!
        end

        true
      end

      def redirect?
        confirmed == "no"
      end

      def redirect_to
        claim_path(journey.routing_name, "upload-employment-proof")
      end

      def latest_blob
        journey_session.employment_proofs.attachments.order(created_at: :desc).first&.blob
      end

      def completed?
        journey_session.answers.confirmed_employment_proof_blob_ids.any?
      end

      def inline_previewable?(blob)
        UploadEmploymentProofForm::INLINE_PREVIEWABLE_CONTENT_TYPES.include?(blob.content_type)
      end

      def radio_options
        [
          Option.new(id: "yes", name: "Yes, add this file"),
          Option.new(id: "no", name: "No, I want to choose a different file")
        ]
      end
    end
  end
end
