module Journeys
  module FurtherEducationPayments
    module CoursesHelper
      include ActionView::Helpers::UrlHelper
      include GovukVisuallyHiddenHelper
      include GovukLinkHelper

      ALL_COURSE_FIELDS = %i[
        building_construction_courses
        chemistry_courses
        computing_courses
        early_years_courses
        engineering_manufacturing_courses
        maths_courses
        physics_courses
      ].freeze

      ALL_SUBJECTS = ALL_COURSE_FIELDS.map { |course_field| course_field.to_s.gsub("_courses", "") }.freeze

      COURSE_DESCRIPTIONS_WITH_INLINE_LINKS = {
        building_construction_courses: {
          esfa_buildingconstruction: [
            "building and construction",
            "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=7"
          ],
          level2_3_apprenticeship: [
            "construction and the built environment occupational route",
            "https://occupational-maps.instituteforapprenticeships.org/maps/route/construction"
          ]
        },
        computing_courses: {
          esfa_digitalpractitioners: [
            "digital technology for practitioners",
            "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=23&PageSize=10&Sort=Status"
          ],
          esfa_digitalusers: [
            "digital technology for users",
            "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=22&PageSize=10&Sort=Status"
          ],
          level2_3_apprenticeship: [
            "digital occupational route",
            "https://occupational-maps.instituteforapprenticeships.org/maps/route/digital"
          ]
        },
        early_years_courses: {
          coursetoeyq: [
            "early years qualification",
            "https://www.gov.uk/government/publications/early-years-qualifications-achieved-in-england"
          ]
        },
        engineering_manufacturing_courses: {
          esfa_engineering: [
            "engineering",
            "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=13&PageSize=10&Sort=Status"
          ],
          esfa_manufacturing: [
            "manufacturing technologies",
            "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=26&PageSize=10&Sort=Status"
          ],
          esfa_transportation: [
            "transportation operations and maintenance",
            "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=47&PageSize=10&Sort=Status"
          ],
          level2_3_apprenticeship: [
            "engineering and manufacturing occupational route",
            "https://occupational-maps.instituteforapprenticeships.org/maps/route/engineering-manufacturing"
          ]
        },
        maths_courses: {
          esfa: [
            "mathematics and statistics",
            "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=28&PageSize=10&Sort=Status"
          ],
          gcse_maths: [
            "other maths qualifications",
            "https://submit-learner-data.service.gov.uk/find-a-learning-aim/LearningAimSearchResult?TeachingYear=2324&HasFilters=False&EFAFundingConditions=EFACONFUNDMATHS"
          ]
        }
      }.freeze

      def course_option_description(course, opts = {})
        course_field = opts.key?(:i18n_form_namespace) ? opts[:i18n_form_namespace] : i18n_form_namespace
        args = {i18n_form_namespace: course_field}

        text, url = COURSE_DESCRIPTIONS_WITH_INLINE_LINKS.dig(course_field.to_sym, course.to_sym)
        args[:link] = govuk_link_to(text, url, new_tab: true) if text.present? && url.present?

        t("options.#{course}", args)
      end
    end
  end
end