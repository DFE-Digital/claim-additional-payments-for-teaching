module Journeys
  module FurtherEducationPayments
    class ChemistryCoursesForm < Form
      include CoursesHelper

      attribute :chemistry_courses, default: []

      before_validation :clean_courses

      validates :chemistry_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :chemistry_courses
      end

      def checkbox_options
        [
          OpenStruct.new(
            id: "alevel_chemistry",
            name: course_option_description("alevel_chemistry")
          ),
          OpenStruct.new(
            id: "gcse_chemistry",
            name: course_option_description("gcse_chemistry")
          ),
          OpenStruct.new(
            id: "ibo_level_3_chemistry",
            name: course_option_description("ibo_level_3_chemistry")
          ),
          OpenStruct.new(
            id: "ibo_level_1_2_myp_chemistry",
            name: course_option_description("ibo_level_1_2_myp_chemistry")
          ),
          OpenStruct.new(
            id: "none",
            name: course_option_description("none")
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(chemistry_courses:)
        journey_session.save!
      end

      def clear_answers_from_session
        journey_session.answers.assign_attributes(chemistry_courses: [])
        journey_session.save!
      end

      private

      def clean_courses
        chemistry_courses.reject!(&:blank?)
      end
    end
  end
end
