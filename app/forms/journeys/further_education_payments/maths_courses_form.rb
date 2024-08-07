module Journeys
  module FurtherEducationPayments
    class MathsCoursesForm < Form
      include CoursesHelper

      attribute :maths_courses, default: []

      before_validation :clean_courses

      validates :maths_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :maths_courses
      end

      def checkbox_options
        [
          OpenStruct.new(
            id: "esfa",
            name: course_option_description("esfa")
          ),
          OpenStruct.new(
            id: "gcse_maths",
            name: course_option_description("gcse_maths")
          ),
          OpenStruct.new(
            id: "none",
            name: course_option_description("none")
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(maths_courses:)
        journey_session.save!
      end

      private

      def clean_courses
        maths_courses.reject!(&:blank?)
      end
    end
  end
end
