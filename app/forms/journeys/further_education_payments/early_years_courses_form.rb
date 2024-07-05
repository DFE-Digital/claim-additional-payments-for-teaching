module Journeys
  module FurtherEducationPayments
    class EarlyYearsCoursesForm < Form
      include ActiveModel::Validations::Callbacks
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::OutputSafetyHelper
      include GovukVisuallyHiddenHelper
      include GovukLinkHelper

      attribute :early_years_courses, default: []

      before_validation :clean_courses

      validates :early_years_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :early_years_courses
      end

      def checkbox_options
        [
          OpenStruct.new(
            id: "eylevel2",
            name: t("options.eylevel2")
          ),
          OpenStruct.new(
            id: "eylevel3",
            name: t("options.eylevel3")
          ),
          OpenStruct.new(
            id: "eytlevel",
            name: t("options.eytlevel")
          ),
          OpenStruct.new(
            id: "coursetoeyq",
            name: t(
              "options.coursetoeyq",
              link: govuk_link_to("early years qualification", "https://www.gov.uk/government/publications/early-years-qualifications-achieved-in-england")
            )
          ),
          OpenStruct.new(
            id: "none",
            name: t("options.none")
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(early_years_courses:)
        journey_session.save!
      end

      private

      def clean_courses
        early_years_courses.reject!(&:blank?)
      end
    end
  end
end
