module Journeys
  module FurtherEducationPayments
    class AnswersPresenter < BaseAnswersPresenter
      include ActionView::Helpers::TranslationHelper

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

      def teaching_responsibilities
        [
          t("further_education_payments.forms.teaching_responsibilities.question"),
          (journey_session.answers.teaching_responsibilities? ? "Yes" : "No"),
          "teaching-responsibilities"
        ]
      end

      def school
        [
          t("further_education_payments.forms.further_education_provision_search.question"),
          journey_session.answers.school.name,
          "further-education-provision-search"
        ]
      end

      def contract_type
        [
          t("further_education_payments.forms.contract_type.question", school_name: journey_session.answers.school.name),
          t(journey_session.answers.contract_type, scope: "further_education_payments.forms.contract_type.options"),
          "contract-type"
        ]
      end

      def teaching_hours_per_week
        [
          t("further_education_payments.forms.teaching_hours_per_week.question", school_name: journey_session.answers.school.name),
          t(journey_session.answers.teaching_hours_per_week, scope: "further_education_payments.forms.teaching_hours_per_week.options"),
          "teaching-hours-per-week"
        ]
      end

      def hours_teaching_eligible_subjects
        [
          t("further_education_payments.forms.hours_teaching_eligible_subjects.question"),
          (journey_session.answers.hours_teaching_eligible_subjects? ? "Yes" : "No"),
          "hours-teaching-eligible-subjects"
        ]
      end

      def further_education_teaching_start_year
        # TODO: pre-xxxx is an ineligible state so this conditional can be removed when the eligility checking is added, it won't be used
        answer = if journey_session.answers.further_education_teaching_start_year =~ /pre-(\d{4})/
          t("further_education_payments.forms.further_education_teaching_start_year.options.before_date", year: $1)
        else
          start_year = journey_session.answers.further_education_teaching_start_year.to_i
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
        answers = journey_session.answers.subjects_taught.map { |subject_taught|
          content_tag(:p, t(subject_taught, scope: "further_education_payments.forms.subjects_taught.options"), class: "govuk-body")
        }.join("").html_safe

        [
          t("further_education_payments.forms.subjects_taught.question"),
          answers,
          "subjects-taught"
        ]
      end

      def half_teaching_hours
        [
          t("further_education_payments.forms.half_teaching_hours.question"),
          (journey_session.answers.half_teaching_hours? ? "Yes" : "No"),
          "half-teaching-hours"
        ]
      end

      def teaching_qualification
        [
          t("further_education_payments.forms.teaching_qualification.question"),
          t(journey_session.answers.teaching_qualification, scope: "further_education_payments.forms.teaching_qualification.options"),
          "teaching-qualification"
        ]
      end

      def subject_to_formal_performance_action
        [
          t("further_education_payments.forms.poor_performance.questions.performance.question"),
          (journey_session.answers.subject_to_formal_performance_action? ? "Yes" : "No"),
          "poor-performance"
        ]
      end

      def subject_to_disciplinary_action
        [
          t("further_education_payments.forms.poor_performance.questions.disciplinary.question"),
          (journey_session.answers.subject_to_disciplinary_action? ? "Yes" : "No"),
          "poor-performance"
        ]
      end
    end
  end
end
