# frozen_string_literal: true

module Journeys
  module TeacherStudentLoanReimbursement
    class UploadedEmploymentProofForm < Form
      attribute :upload_another, :string

      validates :upload_another, inclusion: {in: %w[yes no], message: "Select yes if you want to upload another document"}

      def save
        return false if invalid?
        return false if upload_another == "yes"
        true
      end

      def redirect?
        upload_another == "yes"
      end

      def redirect_to
        claim_path(journey.routing_name, "upload-employment-proof")
      end

      def uploaded_blobs
        confirmed_ids = journey_session.answers.confirmed_employment_proof_blob_ids
        ActiveStorage::Blob.where(id: confirmed_ids).order(created_at: :asc)
      end

      def completed?
        journey_session.answers.confirmed_employment_proof_blob_ids.any?
      end
    end
  end
end
