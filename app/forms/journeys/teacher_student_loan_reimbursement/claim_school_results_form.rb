module Journeys
  module TeacherStudentLoanReimbursement
    class ClaimSchoolResultsForm < Form
      attribute :possible_claim_school_id, :string # school GUID

      validates :possible_claim_school_id, presence: {message: i18n_error_message(:blank)}

      def radio_options
        results
      end

      def save
        return unless valid?

        journey_session.answers.assign_attributes(
          claim_school_id: possible_claim_school_id
        )
        journey_session.save!
      end

      def completed?
        journey_session.answers.claim_school_id.present?
      end

      private

      def results
        @results ||= if journey_session.answers.possible_claim_school_id.present?
          School.where(id: possible_claim_school_id)
        else
          School.search(provision_search)
        end
      end

      def provision_search
        journey_session.answers.provision_search
      end
    end
  end
end
