module Journeys
  module FurtherEducationPayments
    class MathsCoursesForm < Form
      include ActiveModel::Validations::Callbacks
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
            name: "ESFA-funded qualifications at level 3 and below in the #{govuk_link_to "mathematics and statistics", "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=28&PageSize=10&Sort=Status"} sector subject area"
          ),
          OpenStruct.new(
            id: "gcse_maths",
            name: "Maths GCSE, functional skills qualifications and #{govuk_link_to "other maths qualifications", "https://submit-learner-data.service.gov.uk/find-a-learning-aim/LearningAimSearchResult?TeachingYear=2324&HasFilters=False&EFAFundingConditions=EFACONFUNDMATHS"} approved for teaching to 16 to 19-year-olds who meet the condition of funding"
          ),
          OpenStruct.new(
            id: "none",
            name: "I do not teach any of these courses"
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
