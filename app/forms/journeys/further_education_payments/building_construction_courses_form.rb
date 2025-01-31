module Journeys
  module FurtherEducationPayments
    class BuildingConstructionCoursesForm < Form
      include CoursesHelper

      attribute :building_construction_courses, default: []

      before_validation :clean_courses

      validates :building_construction_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :building_construction_courses
      end

      def checkbox_options
        [
          OpenStruct.new(
            id: "level3_buildingconstruction_approved",
            name: course_option_description("level3_buildingconstruction_approved")
          ),
          OpenStruct.new(
            id: "tlevel_building",
            name: course_option_description("tlevel_building")
          ),
          OpenStruct.new(
            id: "tlevel_onsiteconstruction",
            name: course_option_description("tlevel_onsiteconstruction")
          ),
          OpenStruct.new(
            id: "tlevel_design_surveying",
            name: course_option_description("tlevel_design_surveying")
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

        journey_session.answers.assign_attributes(building_construction_courses:)
        journey_session.save!
      end

      def clear_answers_from_session
        journey_session.answers.assign_attributes(building_construction_courses: [])
        journey_session.save!
      end

      private

      def clean_courses
        building_construction_courses.reject!(&:blank?)
      end
    end
  end
end
