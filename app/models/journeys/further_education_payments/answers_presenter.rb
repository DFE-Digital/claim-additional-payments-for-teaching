module Journeys
  module FurtherEducationPayments
    class AnswersPresenter < BaseAnswersPresenter
      include ActionView::Helpers::TranslationHelper
      include CoursesHelper

      def identity_answers
        [].tap do |a|
          a << [t("questions.name"), answers.full_name, "personal-details"] if show_name?
          a << [t("forms.address.questions.your_address"), answers.address, "address"]

          a << [t("further_education_payments.forms.passport.question"), (answers.valid_passport ? "Yes" : "No"), "passport"] if !answers.valid_passport.nil?
          a << [t("further_education_payments.forms.passport.conditional_question"), answers.passport_number, "passport"] if answers.passport_number.present?

          a << [t("questions.date_of_birth"), date_of_birth_string, "personal-details"] if show_dob?
          a << payroll_gender
          a << teacher_reference_number if show_trn?
          a << [t("questions.national_insurance_number"), answers.national_insurance_number, "personal-details"] if show_nino?
          a << [t("questions.email_address"), answers.email_address, "email-address"] unless show_email_select?
          a << [text_for(:select_email), answers.email_address, "select-email"] if show_email_select?
          a << [t("questions.provide_mobile_number"), answers.provide_mobile_number? ? "Yes" : "No", "provide-mobile-number"] unless show_mobile_select?
          a << [t("questions.mobile_number"), answers.mobile_number, "mobile-number"] unless show_mobile_select? || !answers.provide_mobile_number?
          a << [t("forms.select_mobile_form.questions.which_number"), answers.mobile_number.present? ? answers.mobile_number : t("forms.select_mobile_form.answers.decline"), "select-mobile"] if show_mobile_select?
        end
      end

      # Formats the eligibility as a list of questions and answers, each
      # accompanied by a slug for changing the answer. Suitable for playback to
      # the claimant for them to review on the check-your-answers page.
      #
      # Returns an array. Each element of this an array is an array of three
      # elements:
      # [0]: question text;
      # [1]: answer text;
      # [2]: slug for changing the answer.
      def eligibility_answers
        [].tap do |a|
          a << teaching_responsibilities
          a << school
          a << contract_type
          a << teaching_hours_per_week
          a << further_education_teaching_start_year
          a << subjects_taught
          a << building_construction_courses
          a << chemistry_courses
          a << computing_courses
          a << early_years_courses
          a << engineering_manufacturing_courses
          a << maths_courses
          a << physics_courses
          a << hours_teaching_eligible_subjects
          a << half_teaching_hours
          a << teaching_qualification
          a << subject_to_formal_performance_action
          a << subject_to_disciplinary_action
        end.compact
      end

      private

      def payroll_gender
        [
          t("further_education_payments.forms.gender.questions.payroll_gender"),
          t("answers.payroll_gender.#{answers.payroll_gender}"),
          "gender"
        ]
      end

      def teacher_reference_number
        [
          t("further_education_payments.forms.teacher_reference_number.questions.teacher_reference_number"),
          answers.teacher_reference_number,
          "teacher-reference-number"
        ]
      end

      def teaching_responsibilities
        [
          t("further_education_payments.forms.teaching_responsibilities.question"),
          (answers.teaching_responsibilities? ? "Yes" : "No"),
          "teaching-responsibilities"
        ]
      end

      def school
        [
          t("further_education_payments.forms.further_education_provision_search.question"),
          answers.school.name,
          "further-education-provision-search"
        ]
      end

      def contract_type
        [
          t("further_education_payments.forms.contract_type.question", school_name: answers.school.name),
          t(answers.contract_type, scope: "further_education_payments.forms.contract_type.options"),
          "contract-type"
        ]
      end

      def teaching_hours_per_week
        [
          t("further_education_payments.forms.teaching_hours_per_week.question", school_name: answers.school.name),
          t(answers.teaching_hours_per_week, scope: "further_education_payments.forms.teaching_hours_per_week.options"),
          "teaching-hours-per-week"
        ]
      end

      def hours_teaching_eligible_subjects
        [
          t("further_education_payments.forms.hours_teaching_eligible_subjects.question"),
          (answers.hours_teaching_eligible_subjects? ? "Yes" : "No"),
          "hours-teaching-eligible-subjects"
        ]
      end

      def further_education_teaching_start_year
        # TODO: pre-xxxx is an ineligible state so this conditional can be removed when the eligility checking is added, it won't be used
        answer = if answers.further_education_teaching_start_year =~ /pre-(\d{4})/
          t("further_education_payments.forms.further_education_teaching_start_year.options.before_date", year: $1)
        else
          start_year = answers.further_education_teaching_start_year.to_i
          end_year = start_year + 1

          t("further_education_payments.forms.further_education_teaching_start_year.options.between_dates", start_year: start_year, end_year: end_year)
        end

        [
          t("further_education_payments.forms.further_education_teaching_start_year.question"),
          answer,
          "further-education-teaching-start-year"
        ]
      end

      def subjects_taught
        subjects_list = answers.subjects_taught.map { |subject_taught|
          content_tag(:p, t(subject_taught, scope: "further_education_payments.forms.subjects_taught.options"), class: "govuk-body")
        }.join("").html_safe

        [
          t("further_education_payments.forms.subjects_taught.question"),
          subjects_list,
          "subjects-taught"
        ]
      end

      def half_teaching_hours
        [
          t("further_education_payments.forms.half_teaching_hours.question"),
          (answers.half_teaching_hours? ? "Yes" : "No"),
          "half-teaching-hours"
        ]
      end

      def teaching_qualification
        [
          t("further_education_payments.forms.teaching_qualification.question"),
          t(answers.teaching_qualification, scope: "further_education_payments.forms.teaching_qualification.options"),
          "teaching-qualification"
        ]
      end

      def subject_to_formal_performance_action
        [
          t("further_education_payments.forms.poor_performance.questions.performance.question"),
          (answers.subject_to_formal_performance_action? ? "Yes" : "No"),
          "poor-performance"
        ]
      end

      def subject_to_disciplinary_action
        [
          t("further_education_payments.forms.poor_performance.questions.disciplinary.question"),
          (answers.subject_to_disciplinary_action? ? "Yes" : "No"),
          "poor-performance"
        ]
      end

      def building_construction_courses
        courses_for_course_field(:building_construction_courses)
      end

      def chemistry_courses
        courses_for_course_field(:chemistry_courses)
      end

      def computing_courses
        courses_for_course_field(:computing_courses)
      end

      def early_years_courses
        courses_for_course_field(:early_years_courses)
      end

      def engineering_manufacturing_courses
        courses_for_course_field(:engineering_manufacturing_courses)
      end

      def maths_courses
        courses_for_course_field(:maths_courses)
      end

      def physics_courses
        courses_for_course_field(:physics_courses)
      end

      def courses_for_course_field(course_field)
        scope = "further_education_payments.forms.#{course_field}"

        courses_list = answers.public_send(course_field).map { |course|
          body = t("options.#{course}", scope: scope, link: link_for_course(course_field, course, link: false))
          content_tag(:p, body, class: "govuk-body")
        }.join("").html_safe

        return nil if courses_list.empty?

        [
          t("further_education_payments.forms.#{course_field}.question_check_your_answers"),
          courses_list,
          course_field.to_s.tr("_", "-")
        ]
      end
    end
  end
end
