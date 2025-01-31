module Journeys
  module FurtherEducationPayments
    class EngineeringManufacturingCoursesForm < Form
      include CoursesHelper

      attribute :engineering_manufacturing_courses, default: []

      before_validation :clean_courses

      validates :engineering_manufacturing_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :engineering_manufacturing_courses
      end

      def checkbox_options
        [
          OpenStruct.new(
            id: "approved_level_321_engineering",
            name: course_option_description("approved_level_321_engineering")
          ),
          OpenStruct.new(
            id: "approved_level_321_manufacturing",
            name: course_option_description("approved_level_321_manufacturing")
          ),
          OpenStruct.new(
            id: "approved_level_321_transportation",
            name: course_option_description("approved_level_321_transportation")
          ),
          OpenStruct.new(
            id: "tlevel_design",
            name: course_option_description("tlevel_design")
          ),
          OpenStruct.new(
            id: "tlevel_maintenance",
            name: course_option_description("tlevel_maintenance")
          ),
          OpenStruct.new(
            id: "tlevel_engineering",
            name: course_option_description("tlevel_engineering")
          ),
          OpenStruct.new(
            id: "level2_3_apprenticeship",
            name: course_option_description("level2_3_apprenticeship")
          ),
          OpenStruct.new(
            id: "none",
            name: course_option_description("none")
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(engineering_manufacturing_courses:)
        journey_session.save!
      end

      def clear_answers_from_session
        journey_session.answers.assign_attributes(engineering_manufacturing_courses: [])
        journey_session.save!
      end

      private

      def clean_courses
        engineering_manufacturing_courses.reject!(&:blank?)
      end
    end
  end
end
