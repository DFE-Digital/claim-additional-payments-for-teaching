module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ChemistryCoursesForm < BaseForm
          include FormHelpers
          include Journeys::FurtherEducationPayments::CoursesHelper

          attribute :provider_verification_chemistry_courses, default: []

          before_validation :clean_courses

          validates(
            :provider_verification_chemistry_courses,
            presence: {
              message: "Select the eligible courses they teach"
            },
            unless: :save_and_exit?
          )

          validates(
            :provider_verification_chemistry_courses,
            included: {
              in: ->(form) { form.checkbox_options.map(&:id) },
              message: "Select the eligible courses they teach"
            },
            allow_blank: :save_and_exit?
          )

          def checkbox_options
            [
              Form::Option.new(
                id: "alevel_chemistry",
                name: course_option_description("alevel_chemistry")
              ),
              Form::Option.new(
                id: "gcse_chemistry",
                name: course_option_description("gcse_chemistry")
              ),
              Form::Option.new(
                id: "ibo_level_3_chemistry",
                name: course_option_description("ibo_level_3_chemistry")
              ),
              Form::Option.new(
                id: "ibo_level_1_2_myp_chemistry",
                name: course_option_description("ibo_level_1_2_myp_chemistry")
              ),
              Form::Option.new(
                id: "none",
                name: "They do not teach any of these courses"
              )
            ]
          end

          def course_field
            :provider_verification_chemistry_courses
          end

          def subject_area_name
            "chemistry"
          end

          private

          def journey
            Journeys::FurtherEducationPayments
          end

          def clean_courses
            provider_verification_chemistry_courses.reject!(&:blank?)
          end
        end
      end
    end
  end
end
