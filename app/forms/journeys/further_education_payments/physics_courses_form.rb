module Journeys
  module FurtherEducationPayments
    class PhysicsCoursesForm < Form
      include CoursesHelper

      attribute :physics_courses, default: []

      before_validation :clean_courses

      validates :physics_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :physics_courses
      end

      def checkbox_options
        [
          Option.new(
            id: "alevel_physics",
            name: course_option_description("alevel_physics")
          ),
          Option.new(
            id: "gcse_physics",
            name: course_option_description("gcse_physics")
          ),
          Option.new(
            id: "ibo_level_1_2_myp_physics",
            name: course_option_description("ibo_level_1_2_myp_physics")
          ),
          Option.new(
            id: "ibo_level_3_physics",
            name: course_option_description("ibo_level_3_physics")
          ),
          Option.new(
            id: "none",
            name: course_option_description("none")
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(physics_courses:)
        journey_session.save!
      end

      def clear_answers_from_session
        if answers.subjects_taught.exclude?("physics")
          journey_session.answers.assign_attributes(physics_courses: [])
          journey_session.save!
        end
      end

      private

      def clean_courses
        physics_courses.reject!(&:blank?)
      end
    end
  end
end
