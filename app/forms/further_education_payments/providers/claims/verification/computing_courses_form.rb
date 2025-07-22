module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ComputingCoursesForm < BaseForm
          include FormHelpers
          include Journeys::FurtherEducationPayments::CoursesHelper

          attribute :provider_verification_computing_courses, default: []

          before_validation :clean_courses

          validates(
            :provider_verification_computing_courses,
            presence: {
              message: "Select the eligible courses they teach"
            },
            unless: :save_and_exit?
          )

          validates(
            :provider_verification_computing_courses,
            included: {
              in: ->(form) { form.checkbox_options.map(&:id) },
              message: "Select the eligible courses they teach"
            },
            allow_blank: :save_and_exit?
          )

          def checkbox_options
            [
              Form::Option.new(
                id: "level3_and_below_ict_for_practitioners",
                name: course_option_description("level3_and_below_ict_for_practitioners")
              ),
              Form::Option.new(
                id: "level3_and_below_ict_for_users",
                name: course_option_description("level3_and_below_ict_for_users")
              ),
              Form::Option.new(
                id: "digitalskills_quals",
                name: course_option_description("digitalskills_quals")
              ),
              Form::Option.new(
                id: "tlevel_digitalsupport",
                name: course_option_description("tlevel_digitalsupport")
              ),
              Form::Option.new(
                id: "tlevel_digitalbusiness",
                name: course_option_description("tlevel_digitalbusiness")
              ),
              Form::Option.new(
                id: "tlevel_digitalproduction",
                name: course_option_description("tlevel_digitalproduction")
              ),
              Form::Option.new(
                id: "ibo_level3_compsci",
                name: course_option_description("ibo_level3_compsci")
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
            :provider_verification_computing_courses
          end

          def subject_area_name
            "computing, including digital and ICT"
          end

          private

          def journey
            Journeys::FurtherEducationPayments
          end

          def clean_courses
            provider_verification_computing_courses.reject!(&:blank?)
          end
        end
      end
    end
  end
end
