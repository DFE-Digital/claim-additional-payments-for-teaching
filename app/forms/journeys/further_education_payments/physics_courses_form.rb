module Journeys
  module FurtherEducationPayments
    class PhysicsCoursesForm < Form
      include ActiveModel::Validations::Callbacks
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::OutputSafetyHelper
      include GovukVisuallyHiddenHelper
      include GovukLinkHelper

      attribute :physics_courses, default: []

      before_validation :clean_courses

      validates :physics_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :physics_courses
      end

      def checkbox_options
        [
          OpenStruct.new(
            id: "alevel_physics",
            name: "A or AS level physics"
          ),
          OpenStruct.new(
            id: "gcse_physics",
            name: "GCSE physics"
          ),
          OpenStruct.new(
            id: "ib_certificate_physics",
            name: "International baccalaureate middle years programme or certificate in physics"
          ),
          OpenStruct.new(
            id: "none",
            name: "I do not teach any of these courses"
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(physics_courses:)
        journey_session.save!
      end

      private

      def clean_courses
        physics_courses.reject!(&:blank?)
      end
    end
  end
end
