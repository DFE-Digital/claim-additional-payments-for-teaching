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
            name: t(
              "options.esfa_buildingconstruction",
              link: govuk_link_to("building and construction", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=7")
            )
          ),
          OpenStruct.new(
            id: "tlevel_building",
            name: t("options.tlevel_building")
          ),
          OpenStruct.new(
            id: "tlevel_onsiteconstruction",
            name: t("options.tlevel_onsiteconstruction")
          ),
          OpenStruct.new(
            id: "tlevel_design_surveying",
            name: t("options.tlevel_design_surveying")
          ),
          OpenStruct.new(
            id: "level2_3_apprenticeship",
            name: t(
              "options.level2_3_apprenticeship",
              link: govuk_link_to("construction and the built environment occupational route", "https://occupational-maps.instituteforapprenticeships.org/maps/route/construction")
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
