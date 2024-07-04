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
            id: "a_as_level_chemistry",
            name: "A or AS level chemistry"
          ),
          OpenStruct.new(
            id: "gcse_chemistry",
            name: "GCSE chemistry"
          ),
          OpenStruct.new(
            id: "international_baccalaureate_middle_years_programme_certificate_chemistry",
            name: "International baccalaureate middle years programme or certificate in chemistry"
          ),
          OpenStruct.new(
            id: "none",
            name: "I do not teach any of these courses"
          ),
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
