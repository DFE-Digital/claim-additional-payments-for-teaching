module Journeys
  module TeacherStudentLoanReimbursement
    class StillTeachingTpsForm < Form
      attribute :employment_status

      validates(
        :employment_status,
        presence: {
          message: ->(form, _) do
            form.i18n_errors_path(
              "select_which_school_currently",
              school_name: form.school.name
            )
          end
        }
      )

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          employment_status: employment_status
        )

        if currently_at_school?
          journey_session.answers.assign_attributes(
            current_school_id: school.id
          )
        else
          journey_session.answers.assign_attributes(
            current_school_id: nil
          )
        end

        journey_session.save!
      end

      def school
        @school ||= answers.recent_tps_school
      end

      private

      def i18n_form_namespace
        "still_teaching"
      end

      def currently_at_school?
        %w[claim_school recent_tps_school].include?(employment_status)
      end
    end
  end
end
