module Journeys
  module FurtherEducationPayments
    class BuildingConstructionCoursesForm < Form
      include ActiveModel::Validations::Callbacks
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::OutputSafetyHelper
      include GovukVisuallyHiddenHelper
      include GovukLinkHelper

      attribute :building_construction_courses, default: []

      before_validation :clean_courses

      validates :building_construction_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :building_construction_courses
      end

      def checkbox_options
        [
          OpenStruct.new(
            id: "esfa_buildingconstruction",
            name: "ESFA-funded qualifications at level 3 and below in the #{govuk_link_to "building and construction", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=7"} sector subject area"
          ),
          OpenStruct.new(
            id: "tlevel_building",
            name: "T Level in building services engineering for construction"
          ),
          OpenStruct.new(
            id: "tlevel_onsiteconstruction",
            name: "T Level in onsite construction"
          ),
          OpenStruct.new(
            id: "tlevel_design_surveying",
            name: "T Level in design, surveying and planning for construction"
          ),
          OpenStruct.new(
            id: "level2_3_apprenticeship",
            name: "Level 2 or level 3 apprenticeships in the #{govuk_link_to "construction and the built environment occupational route", "https://occupational-maps.instituteforapprenticeships.org/maps/route/construction"}"
          ),
          OpenStruct.new(
            id: "none",
            name: "I do not teach any of these courses"
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(building_construction_courses:)
        journey_session.save!
      end

      private

      def clean_courses
        building_construction_courses.reject!(&:blank?)
      end
    end
  end
end
