module Journeys
  module TeacherStudentLoanReimbursement
    class StillTeachingForm < Form
      attribute :employment_status

      validates :employment_status, presence: {message: ->(form, _) { form.error_message }}

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          employment_status:,
          current_school_id: save_current_school? ? school.id : nil
        )

        journey_session.save!
      end

      def school
        if school_from_tps?
          answers.recent_tps_school
        else
          answers.claim_school
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
        if school_from_tps?
          "tps_school"
        else
          "claim_school"
        end
      end

      private

      def school_from_tps?
        answers.logged_in_with_tid_and_has_recent_tps_school?
      end

      def school_from_claim?
        !school_from_tps?
      end

      def save_current_school?
        return false unless currently_at_school?
        return false if school_from_claim? && !school.open?

        true
      end

      def currently_at_school?
        %w[claim_school recent_tps_school].include?(employment_status)
      end
    end
  end
end
