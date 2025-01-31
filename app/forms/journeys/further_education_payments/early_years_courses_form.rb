module Journeys
  module FurtherEducationPayments
    class EarlyYearsCoursesForm < Form
      include CoursesHelper

      attribute :early_years_courses, default: []

      before_validation :clean_courses

      validates :early_years_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :early_years_courses
      end

      def checkbox_options
        [
          OpenStruct.new(
            id: "eylevel2",
            name: course_option_description("eylevel2")
          ),
          OpenStruct.new(
            id: "eylevel3",
            name: course_option_description("eylevel3")
          ),
          OpenStruct.new(
            id: "eytlevel",
            name: course_option_description("eytlevel")
          ),
          OpenStruct.new(
            id: "coursetoeyq",
            name: course_option_description("coursetoeyq")
          ),
          OpenStruct.new(
            id: "none",
            name: course_option_description("none")
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(early_years_courses:)
        journey_session.save!
      end

      def clear_answers_from_session
        journey_session.answers.assign_attributes(early_years_courses: [])
        journey_session.save!
      end

      private

      def clean_courses
        early_years_courses.reject!(&:blank?)
      end
    end
  end
end
