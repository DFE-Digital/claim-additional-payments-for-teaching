module Journeys
  module FurtherEducationPayments
    class MathsCoursesForm < Form
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::OutputSafetyHelper
      include GovukVisuallyHiddenHelper
      include GovukLinkHelper

      attribute :maths_courses, default: []

      before_validation :clean_courses

      validates :maths_courses,
        presence: {message: i18n_error_message(:inclusion)},
        inclusion: {in: ->(form) { form.checkbox_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def course_field
        :maths_courses
      end

      def checkbox_options
        [
          OpenStruct.new(
            id: "esfa",
            name: t(
              "options.esfa",
              link: govuk_link_to("mathematics and statistics", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=28&PageSize=10&Sort=Status", new_tab: true)
            )
          ),
          OpenStruct.new(
            id: "gcse_maths",
            name: t(
              "options.gcse_maths",
              link: govuk_link_to("other maths qualifications", "https://submit-learner-data.service.gov.uk/find-a-learning-aim/LearningAimSearchResult?TeachingYear=2324&HasFilters=False&EFAFundingConditions=EFACONFUNDMATHS", new_tab: true)
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

        journey_session.answers.assign_attributes(maths_courses:)
        journey_session.save!
      end

      private

      def clean_courses
        maths_courses.reject!(&:blank?)
      end
    end
  end
end
