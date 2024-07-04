module Journeys
  module FurtherEducationPayments
    class ComputingCoursesForm < Form
      include ActiveModel::Validations::Callbacks
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::OutputSafetyHelper
      include GovukVisuallyHiddenHelper
      include GovukLinkHelper

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
            name: "ESFA-funded qualifications at level 3 and below in the #{govuk_link_to "digital technology for practitioners", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=23&PageSize=10&Sort=Status"} sector subject area"
          ),
          OpenStruct.new(
            id: "esfa_digitalusers",
            name: "ESFA-funded qualifications at level 3 and below in the #{govuk_link_to "digital technology for users", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=22&PageSize=10&Sort=Status"} sector subject area"
          ),
          OpenStruct.new(
            id: "digitalskills_quals",
            name: "Digital functional skills qualifications and essential digital skills qualifications"
          ),
          OpenStruct.new(
            id: "tlevel_digitalsupport",
            name: "T Level in digital support services"
          ),
          OpenStruct.new(
            id: "tlevel_digitalbusiness",
            name: "T Level in digital business services"
          ),
          OpenStruct.new(
            id: "tlevel_digitalproduction",
            name: "T Level in digital production, design and development"
          ),
          OpenStruct.new(
            id: "ib_certificate_compsci",
            name: "International baccalaureate certificate in computer science"
          ),
          OpenStruct.new(
            id: "level2_3_apprenticeship",
            name: "Level 2 or level 3 apprenticeships in the #{govuk_link_to "digital occupational route", "https://occupational-maps.instituteforapprenticeships.org/maps/route/digital"}"
          ),
          OpenStruct.new(
            id: "none",
            name: "I do not teach any of these courses"
          ),
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
