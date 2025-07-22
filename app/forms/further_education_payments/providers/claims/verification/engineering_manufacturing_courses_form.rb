module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class EngineeringManufacturingCoursesForm < BaseForm
          include FormHelpers
          include Journeys::FurtherEducationPayments::CoursesHelper

          attribute :provider_verification_engineering_manufacturing_courses, default: []

          before_validation :clean_courses

          validates(
            :provider_verification_engineering_manufacturing_courses,
            presence: {
              message: "Select the eligible courses they teach"
            },
            unless: :save_and_exit?
          )

          validates(
            :provider_verification_engineering_manufacturing_courses,
            included: {
              in: ->(form) { form.checkbox_options.map(&:id) },
              message: "Select the eligible courses they teach"
            },
            allow_blank: :save_and_exit?
          )

          def checkbox_options
            [
              Form::Option.new(
                id: "approved_level_321_engineering",
                name: course_option_description("approved_level_321_engineering")
              ),
              Form::Option.new(
                id: "approved_level_321_manufacturing",
                name: course_option_description("approved_level_321_manufacturing")
              ),
              Form::Option.new(
                id: "approved_level_321_transportation",
                name: course_option_description("approved_level_321_transportation")
              ),
              Form::Option.new(
                id: "tlevel_design",
                name: course_option_description("tlevel_design")
              ),
              Form::Option.new(
                id: "tlevel_maintenance",
                name: course_option_description("tlevel_maintenance")
              ),
              Form::Option.new(
                id: "tlevel_engineering",
                name: course_option_description("tlevel_engineering")
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
            :provider_verification_engineering_manufacturing_courses
          end

          def subject_area_name
            "engineering and manufacturing"
          end

          private

          def journey
            Journeys::FurtherEducationPayments
          end

          def clean_courses
            provider_verification_engineering_manufacturing_courses.reject!(&:blank?)
          end
        end
      end
    end
  end
end
