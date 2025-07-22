module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class BuildingConstructionCoursesForm < BaseForm
          include FormHelpers
          include Journeys::FurtherEducationPayments::CoursesHelper

          attribute :provider_verification_building_construction_courses, default: []

          before_validation :clean_courses

          validates(
            :provider_verification_building_construction_courses,
            presence: {
              message: "Select the eligible courses they teach"
            },
            unless: :save_and_exit?
          )

          validates(
            :provider_verification_building_construction_courses,
            included: {
              in: ->(form) { form.checkbox_options.map(&:id) },
              message: "Select the eligible courses they teach"
            },
            allow_blank: :save_and_exit?
          )

          def checkbox_options
            [
              Form::Option.new(
                id: "level3_buildingconstruction_approved",
                name: course_option_description("level3_buildingconstruction_approved")
              ),
              Form::Option.new(
                id: "tlevel_building",
                name: course_option_description("tlevel_building")
              ),
              Form::Option.new(
                id: "tlevel_onsiteconstruction",
                name: course_option_description("tlevel_onsiteconstruction")
              ),
              Form::Option.new(
                id: "tlevel_design_surveying",
                name: course_option_description("tlevel_design_surveying")
              ),
              Form::Option.new(
                id: "level2_3_apprenticeship",
                name: course_option_description("level2_3_apprenticeship")
              ),
              Form::Option.new(
                id: "none",
                name: "They do not teach any of these courses"
              )
            ]
          end

          def course_field
            :provider_verification_building_construction_courses
          end

          def subject_area_name
            "building and construction"
          end

          private

          def journey
            Journeys::FurtherEducationPayments
          end

          def clean_courses
            provider_verification_building_construction_courses.reject!(&:blank?)
          end
        end
      end
    end
  end
end
