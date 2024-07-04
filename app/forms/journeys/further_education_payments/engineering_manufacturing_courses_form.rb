module Journeys
  module FurtherEducationPayments
    class EngineeringManufacturingCoursesForm < Form
      include ActiveModel::Validations::Callbacks
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::OutputSafetyHelper
      include GovukVisuallyHiddenHelper
      include GovukLinkHelper

      attribute :engineering_manufacturing_courses, default: []

      before_validation :clean_courses

      validates :engineering_manufacturing_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :engineering_manufacturing_courses
      end

      def checkbox_options
        [
          OpenStruct.new(
            id: "esfa_engineering",
            name: "ESFA-funded qualifications at level 3 and below in the #{govuk_link_to "engineering", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=13&PageSize=10&Sort=Status"} sector subject area"
          ),
          OpenStruct.new(
            id: "esfa_manufacturing",
            name: "ESFA-funded qualifications at level 3 and below in the #{govuk_link_to "manufacturing technologies", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=26&PageSize=10&Sort=Status"} sector subject area"
          ),
          OpenStruct.new(
            id: "esfa_transportation",
            name: "ESFA-funded qualifications at level 3 and below in the #{govuk_link_to "transportation operations and maintenance", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=47&PageSize=10&Sort=Status"} sector subject area"
          ),
          OpenStruct.new(
            id: "tlevel_design",
            name: "T Level in design and development for engineering and manufacturing"
          ),
          OpenStruct.new(
            id: "tlevel_maintenance",
            name: "T Level in maintenance, installation and repair for engineering and manufacturing"
          ),
          OpenStruct.new(
            id: "tlevel_engineering",
            name: "T Level in engineering, manufacturing, processing and control"
          ),
          OpenStruct.new(
            id: "level2_3_apprenticeship",
            name: "Level 2 or level 3 apprenticeships in the #{govuk_link_to "engineering and manufacturing occupational route", "https://occupational-maps.instituteforapprenticeships.org/maps/route/engineering-manufacturing"}"
          ),

          OpenStruct.new(
            id: "none",
            name: "I do not teach any of these courses"
          ),
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(engineering_manufacturing_courses:)
        journey_session.save!
      end

      private

      def clean_courses
        engineering_manufacturing_courses.reject!(&:blank?)
      end
    end
  end
end
