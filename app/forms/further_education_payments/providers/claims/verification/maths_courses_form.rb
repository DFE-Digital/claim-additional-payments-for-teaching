module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class MathsCoursesForm < BaseForm
          include FormHelpers
          include Journeys::FurtherEducationPayments::CoursesHelper

          attribute :provider_verification_maths_courses, default: []

          before_validation :clean_courses

          validates(
            :provider_verification_maths_courses,
            presence: {
              message: "Select the eligible courses they teach"
            },
            unless: :save_and_exit?
          )

          validates(
            :provider_verification_maths_courses,
            included: {
              in: ->(form) { form.checkbox_options.map(&:id) },
              message: "Select the eligible courses they teach"
            },
            allow_blank: :save_and_exit?
          )

          def checkbox_options
            [
              Form::Option.new(
                id: "approved_level_321_maths",
                name: course_option_description("approved_level_321_maths")
              ),
              Form::Option.new(
                id: "gcse_maths",
                name: course_option_description("gcse_maths")
              ),
              Form::Option.new(
                id: "none",
                name: "They do not teach any of these courses"
              )
            ]
          end

          def course_field
            :provider_verification_maths_courses
          end

          def subject_area_name
            "maths"
          end

          private

          def journey
            Journeys::FurtherEducationPayments
          end

          def clean_courses
            provider_verification_maths_courses.reject!(&:blank?)
          end
        end
      end
    end
  end
end
