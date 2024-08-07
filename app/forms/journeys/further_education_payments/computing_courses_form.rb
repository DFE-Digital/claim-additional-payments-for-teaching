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
          OpenStruct.new(
            id: "esfa_digitalpractitioners",
            name: course_option_description("esfa_digitalpractitioners")
          ),
          OpenStruct.new(
            id: "esfa_digitalusers",
            name: course_option_description("esfa_digitalusers")
          ),
          OpenStruct.new(
            id: "digitalskills_quals",
            name: course_option_description("digitalskills_quals")
          ),
          OpenStruct.new(
            id: "tlevel_digitalsupport",
            name: course_option_description("tlevel_digitalsupport")
          ),
          OpenStruct.new(
            id: "tlevel_digitalbusiness",
            name: course_option_description("tlevel_digitalbusiness")
          ),
          OpenStruct.new(
            id: "tlevel_digitalproduction",
            name: course_option_description("tlevel_digitalproduction")
          ),
          OpenStruct.new(
            id: "ib_certificate_compsci",
            name: course_option_description("ib_certificate_compsci")
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

        journey_session.answers.assign_attributes(computing_courses:)
        journey_session.save!
      end

      private

      def clean_courses
        computing_courses.reject!(&:blank?)
      end
    end
  end
end
