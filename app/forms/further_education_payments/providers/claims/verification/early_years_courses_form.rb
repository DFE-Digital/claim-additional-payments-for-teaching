module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class EarlyYearsCoursesForm < BaseForm
          include FormHelpers
          include Journeys::FurtherEducationPayments::CoursesHelper

          attribute :provider_verification_early_years_courses, default: []

          before_validation :clean_courses

          validates(
            :provider_verification_early_years_courses,
            presence: {
              message: "Select the eligible courses they teach"
            },
            unless: :save_and_exit?
          )

          validates(
            :provider_verification_early_years_courses,
            included: {
              in: ->(form) { form.checkbox_options.map(&:id) },
              message: "Select the eligible courses they teach"
            },
            allow_blank: :save_and_exit?
          )

          def checkbox_options
            [
              Form::Option.new(
                id: "eylevel2",
                name: course_option_description("eylevel2")
              ),
              Form::Option.new(
                id: "eylevel3",
                name: course_option_description("eylevel3")
              ),
              Form::Option.new(
                id: "eytlevel",
                name: course_option_description("eytlevel")
              ),
              Form::Option.new(
                id: "coursetoeyq",
                name: course_option_description("coursetoeyq")
              ),
              Form::Option.new(
                id: "none",
                name: "They do not teach any of these courses"
              )
            ]
          end

          def course_field
            :provider_verification_early_years_courses
          end

          def subject_area_name
            "early years"
          end

          private

          def journey
            Journeys::FurtherEducationPayments
          end

          def clean_courses
            provider_verification_early_years_courses.reject!(&:blank?)
          end
        end
      end
    end
  end
end
