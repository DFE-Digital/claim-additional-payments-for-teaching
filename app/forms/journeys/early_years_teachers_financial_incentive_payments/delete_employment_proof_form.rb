# frozen_string_literal: true

module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class DeleteEmploymentProofForm < Form
      attribute :confirmed, :string
      attribute :blob_id, :string

      validates :confirmed, inclusion: {in: %w[yes no], message: "Select yes to delete this file"}

      def save
        return false if invalid?

        if confirmed == "yes"
          journey_session.employment_proofs.attachments.find_by(blob_id: blob_id)&.purge
          journey_session.answers.confirmed_employment_proof_blob_ids.delete(blob_id)
          journey_session.save!
        end

        false
      end

      def redirect?
        confirmed.in?(%w[yes no])
      end

      def redirect_to
        if confirmed == "yes" && journey_session.answers.confirmed_employment_proof_blob_ids.none?
          claim_path(journey.routing_name, "upload-employment-proof")
        else
          claim_path(journey.routing_name, "uploaded-employment-proof")
        end
      end

      def blob_to_delete
        journey_session.employment_proofs.attachments.find_by(blob_id: blob_id)&.blob
      end

      def redirect_to_next_slug?
        params[:blob_id].blank?
      end

      def completed?
        true
      end

      def flash_message
        "File deleted" if confirmed == "yes"
      end

      def radio_options
        [
          Option.new(id: "yes", name: "Yes"),
          Option.new(id: "no", name: "No")
        ]
      end

      private

      def load_current_value(attribute)
        return params[:blob_id] if attribute == "blob_id"
        super
      end
    end
  end
end
