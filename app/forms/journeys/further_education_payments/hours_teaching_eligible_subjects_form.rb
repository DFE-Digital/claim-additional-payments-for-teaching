module Journeys
  module FurtherEducationPayments
    class HoursTeachingEligibleSubjectsForm < Form
      include CoursesHelper

      attribute :hours_teaching_eligible_subjects, :boolean

      validates :hours_teaching_eligible_subjects,
        inclusion: {
          in: [true, false],
          message: i18n_error_message(:inclusion)
        }

      def radio_options
        [
          Option.new(id: true, name: "Yes"),
          Option.new(id: false, name: "No")
        ]
      end

      def courses
        ALL_COURSE_FIELDS.map { |course_field|
          course_descriptions(course_field)
        }.flatten
      end

      def save
        return false unless valid?

        journey_session.answers.update!(hours_teaching_eligible_subjects:)
      end

      def clear_answers_from_session
        journey_session.answers.update!(hours_teaching_eligible_subjects: nil)
      end

      private

      def course_descriptions(course_field)
        journey_session.answers.public_send(course_field).reject { |course|
          course == "none"
        }.map { |course|
          course_option_description(course, i18n_form_namespace: course_field).html_safe
        }
      end
    end
  end
end
