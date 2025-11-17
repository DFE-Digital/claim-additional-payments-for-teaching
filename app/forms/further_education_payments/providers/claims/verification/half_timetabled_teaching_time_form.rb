module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class HalfTimetabledTeachingTimeForm < BaseForm
          include Journeys::FurtherEducationPayments::CoursesHelper

          attribute :provider_verification_half_timetabled_teaching_time, :boolean

          validates(
            :provider_verification_half_timetabled_teaching_time,
            included: {
              in: ->(form) { form.radio_options.map(&:id) },
              message: ->(form, _data) do
                "Select yes if #{form.claimant_name} spent at least half of " \
                "their timetabled teaching hours teaching these courses"
              end
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
            claimant_selected_courses.map do |subject_area, course|
              I18n.t(
                "further_education_payments.forms.#{subject_area}_courses.options.#{course}",
                link: link_for_course("#{subject_area}_courses", course)
              ).html_safe
            end
          end

          private

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

          def journey
            Journeys::FurtherEducationPayments
          end
        end
      end
    end
  end
end
