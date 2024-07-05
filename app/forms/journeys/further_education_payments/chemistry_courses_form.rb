module Journeys
  module FurtherEducationPayments
    class ChemistryCoursesForm < Form
      include ActiveModel::Validations::Callbacks
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::OutputSafetyHelper
      include GovukVisuallyHiddenHelper
      include GovukLinkHelper

      attribute :chemistry_courses, default: []

      before_validation :clean_courses

      validates :chemistry_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :chemistry_courses
      end

      def checkbox_options
        [
          OpenStruct.new(
            id: "alevel_chemistry",
            name: t("options.alevel_chemistry")
          ),
          OpenStruct.new(
            id: "gcse_chemistry",
            name: t("options.gcse_chemistry")
          ),
          OpenStruct.new(
            id: "ib_certificate_chemistry",
            name: t("options.ib_certificate_chemistry")
          ),
          OpenStruct.new(
            id: "none",
            name: t("options.none")
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(chemistry_courses:)
        journey_session.save!
      end

      private

      def clean_courses
        chemistry_courses.reject!(&:blank?)
      end
    end
  end
end
