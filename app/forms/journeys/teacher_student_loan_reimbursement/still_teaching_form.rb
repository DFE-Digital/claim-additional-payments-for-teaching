module Journeys
  module TeacherStudentLoanReimbursement
    class StillTeachingForm < Form
      attribute :employment_status

      validates(
        :employment_status,
        presence: {
          message: ->(form, _) do
            if form.school.open?
              form.i18n_errors_path(
                "select_which_school_currently",
                school_name: form.school.name
              )
            else
              form.i18n_errors_path("select_are_you_still_employed")
            end
          end
        }
      )

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          employment_status: employment_status
        )

        if currently_at_school? && school.open?
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
        @school ||= answers.claim_school
      end

      def radio_options
        if school.open?
          [
            Option.new(
              id: :claim_school,
              name: "Yes, at #{school.name}"
            ),
            Option.new(
              id: :different_school,
              name: "Yes, at another school"
            ),
            Option.new(
              id: :no_school,
              name: "No"
            )
          ]
        else
          [
            Option.new(
              id: :different_school,
              name: "Yes"
            ),
            Option.new(
              id: :no_school,
              name: "No"
            )
          ]
        end
      end

      private

      def currently_at_school?
        %w[claim_school recent_tps_school].include?(employment_status)
      end
    end
  end
end
