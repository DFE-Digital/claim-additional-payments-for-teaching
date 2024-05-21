module Journeys
  module TeacherStudentLoanReimbursement
    class StillTeachingForm < Form
      attribute :employment_status
      attribute :current_school_id

      validates :employment_status, presence: {message: ->(form, _) { form.error_message }}

      def save
        return false unless valid?

        update!(
          eligibility_attributes: {
            employment_status:,
            current_school_id: currently_at_school? ? current_school_id : nil
          }
        )
      end

      def school
        if journey_session.logged_in_with_tid_and_has_recent_tps_school?
          journey_session.recent_tps_school
        else
          claim.eligibility.claim_school
        end
      end

      def error_message
        if school.open?
          i18n_errors_path("select_which_school_currently", school_name: school.name)
        else
          i18n_errors_path("select_are_you_still_employed")
        end
      end

      # Helper used in the view to choose partials and locale keys
      def tps_or_claim_school
        if journey_session.logged_in_with_tid_and_has_recent_tps_school?
          "tps_school"
        else
          "claim_school"
        end
      end

      private

      def currently_at_school?
        %w[claim_school recent_tps_school].include?(employment_status)
      end
    end
  end
end
