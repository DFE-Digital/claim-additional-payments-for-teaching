module Journeys
  module FurtherEducationPayments
    class EngineeringManufacturingCoursesForm < Form
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
            name: t(
              "options.esfa_engineering",
              link: govuk_link_to("engineering", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=13&PageSize=10&Sort=Status", new_tab: true)
            )
          ),
          OpenStruct.new(
            id: "esfa_manufacturing",
            name: t(
              "options.esfa_manufacturing",
              link: govuk_link_to("manufacturing technologies", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=26&PageSize=10&Sort=Status", new_tab: true)
            )
          ),
          OpenStruct.new(
            id: "esfa_transportation",
            name: t(
              "options.esfa_transportation",
              link: govuk_link_to("transportation operations and maintenance", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=47&PageSize=10&Sort=Status", new_tab: true)
            )
          ),
          OpenStruct.new(
            id: "tlevel_design",
            name: t("options.tlevel_design")
          ),
          OpenStruct.new(
            id: "tlevel_maintenance",
            name: t("options.tlevel_maintenance")
          ),
          OpenStruct.new(
            id: "tlevel_engineering",
            name: t("options.tlevel_engineering")
          ),
          OpenStruct.new(
            id: "level2_3_apprenticeship",
            name: t(
              "options.level2_3_apprenticeship",
              link: govuk_link_to("engineering and manufacturing occupational route", "https://occupational-maps.instituteforapprenticeships.org/maps/route/engineering-manufacturing", new_tab: true)
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
