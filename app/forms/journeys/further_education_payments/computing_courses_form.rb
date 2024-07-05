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
            name: t(
              "options.esfa_digitalpractitioners",
              link: govuk_link_to("digital technology for practitioners", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=23&PageSize=10&Sort=Status")
            )
          ),
          OpenStruct.new(
            id: "esfa_digitalusers",
            name: t(
              "options.esfa_digitalusers",
              link: govuk_link_to("digital technology for users", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=22&PageSize=10&Sort=Status")
            )
          ),
          OpenStruct.new(
            id: "digitalskills_quals",
            name: t("options.digitalskills_quals")
          ),
          OpenStruct.new(
            id: "tlevel_digitalsupport",
            name: t("options.tlevel_digitalsupport")
          ),
          OpenStruct.new(
            id: "tlevel_digitalbusiness",
            name: t("options.tlevel_digitalbusiness")
          ),
          OpenStruct.new(
            id: "tlevel_digitalproduction",
            name: t("options.tlevel_digitalproduction")
          ),
          OpenStruct.new(
            id: "ib_certificate_compsci",
            name: t("options.ib_certificate_compsci")
          ),
          OpenStruct.new(
            id: "level2_3_apprenticeship",
            name: t(
              "options.level2_3_apprenticeship",
              link: govuk_link_to("digital occupational route", "https://occupational-maps.instituteforapprenticeships.org/maps/route/digital")
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
