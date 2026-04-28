# frozen_string_literal: true

module Journeys
  module TeacherStudentLoanReimbursement
    class ReviewEmploymentProofForm < Form
      attribute :confirmed, :string
      attribute :blob_id, :string

      validates :confirmed, inclusion: {in: %w[yes no], message: "Select yes if the file is correct"}

      def save
        return false if invalid?

        if confirmed == "no"
          journey_session.employment_proofs.attachments.find_by(blob_id: blob_id)&.purge
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
        if journey_session.answers.confirmed_employment_proof_blob_ids.any?
          claim_path(journey.routing_name, "uploaded-employment-proof")
        else
          claim_path(journey.routing_name, "upload-employment-proof")
        end
      end

      def latest_blob
        journey_session.employment_proofs.attachments.order(created_at: :desc).first&.blob
      end

      def completed?
        journey_session.answers.confirmed_employment_proof_blob_ids.any?
      end
    end
  end
end
