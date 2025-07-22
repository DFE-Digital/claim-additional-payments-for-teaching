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
          Option.new(
            id: "alevel_chemistry",
            name: course_option_description("alevel_chemistry")
          ),
          Option.new(
            id: "gcse_chemistry",
            name: course_option_description("gcse_chemistry")
          ),
          Option.new(
            id: "ibo_level_3_chemistry",
            name: course_option_description("ibo_level_3_chemistry")
          ),
          Option.new(
            id: "ibo_level_1_2_myp_chemistry",
            name: course_option_description("ibo_level_1_2_myp_chemistry")
          ),
          Option.new(
            id: "none",
            name: "They do not teach any of these courses"
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(chemistry_courses:)
        journey_session.save!
      end

      def clear_answers_from_session
        if answers.subjects_taught.exclude?("chemistry")
          journey_session.answers.assign_attributes(chemistry_courses: [])
          journey_session.save!
        end
      end

      private

      def clean_courses
        chemistry_courses.reject!(&:blank?)
      end
    end
  end
end
