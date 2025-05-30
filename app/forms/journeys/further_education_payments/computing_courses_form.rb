module Journeys
  module FurtherEducationPayments
    class ComputingCoursesForm < Form
      include CoursesHelper

      attribute :computing_courses, default: []

      before_validation :clean_courses

      validates :computing_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :computing_courses
      end

      def checkbox_options
        [
          Option.new(
            id: "level3_and_below_ict_for_practitioners",
            name: course_option_description("level3_and_below_ict_for_practitioners")
          ),
          Option.new(
            id: "level3_and_below_ict_for_users",
            name: course_option_description("level3_and_below_ict_for_users")
          ),
          Option.new(
            id: "digitalskills_quals",
            name: course_option_description("digitalskills_quals")
          ),
          Option.new(
            id: "tlevel_digitalsupport",
            name: course_option_description("tlevel_digitalsupport")
          ),
          Option.new(
            id: "tlevel_digitalbusiness",
            name: course_option_description("tlevel_digitalbusiness")
          ),
          Option.new(
            id: "tlevel_digitalproduction",
            name: course_option_description("tlevel_digitalproduction")
          ),
          Option.new(
            id: "ibo_level3_compsci",
            name: course_option_description("ibo_level3_compsci")
          ),
          Option.new(
            id: "level2_3_apprenticeship",
            name: course_option_description("level2_3_apprenticeship")
          ),
          Option.new(
            id: "none",
            name: course_option_description("none")
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(computing_courses:)
        journey_session.save!
      end

      def clear_answers_from_session
        if answers.subjects_taught.exclude?("computing")
          journey_session.answers.assign_attributes(computing_courses: [])
          journey_session.save!
        end
      end

      private

      def clean_courses
        computing_courses.reject!(&:blank?)
      end
    end
  end
end
