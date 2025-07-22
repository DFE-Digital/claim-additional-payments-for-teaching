module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class HalfTimetabledTeachingTimeForm < BaseForm
          include FormHelpers
          include Journeys::FurtherEducationPayments::CoursesHelper

          attribute :provider_verification_half_timetabled_teaching_time, :boolean

          validates(
            :provider_verification_half_timetabled_teaching_time,
            included: {
              in: ->(form) { form.radio_options.map(&:id) },
              message: "Tell us if they spend at least half their timetabled teaching time teaching these courses"
            },
            allow_nil: :save_and_exit?
          )

          def radio_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

          def course_descriptions
            courses.map do |subject_area, course|
              course_option_description(course, i18n_form_namespace: "#{subject_area}_courses").html_safe
            end
          end

          private

          def courses
            if eligibility.provider_verification_subjects_taught?
              claimant_selected_courses
            else
              provider_selected_courses
            end
          end

          def claimant_selected_courses
            eligibility
              .subjects_taught
              .flat_map do |subject_area|
                area_courses = eligibility.public_send("#{subject_area}_courses").reject { |subject| subject == "none" }

                area_courses.map do |course|
                  [subject_area, course]
                end
              end
          end

          def all_subject_areas
            %w[
              building_construction_courses
              chemistry_courses
              computing_courses
              early_years_courses
              engineering_manufacturing_courses
              maths_courses
              physics_courses
            ]
          end

          def provider_selected_courses
            eligibility
              .provider_verification_actual_subjects_taught
              .flat_map do |subject_area|
                area_courses = eligibility.public_send("provider_verification_#{subject_area}_courses").reject { |subject| subject == "none" }

                area_courses.map do |course|
                  [subject_area, course]
                end
              end
          end

          def journey
            Journeys::FurtherEducationPayments
          end
        end
      end
    end
  end
end
