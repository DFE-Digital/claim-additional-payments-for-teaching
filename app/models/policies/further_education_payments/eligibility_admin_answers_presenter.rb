module Policies
  module FurtherEducationPayments
    class EligibilityAdminAnswersPresenter
      include Admin::PresenterMethods
      include ActionView::Helpers::NumberHelper

      attr_reader :eligibility

      def initialize(eligibility)
        @eligibility = eligibility
      end

      def answers
        [].tap do |a|
          a << current_school
        end
      end

      def provider_details
        [
          teaching_responsibilities,
          fe_provider
        ]
      end

      def employment_contract
        [
          contract_type,
          teaching_hours_per_week
        ]
      end

      def academic_year_claimant_started_teaching
        [
          [
            question(:further_education_teaching_start_year),
            "September #{eligibility.further_education_teaching_start_year.to_i} " \
            "to August #{eligibility.further_education_teaching_start_year.to_i + 1}"
          ]
        ]
      end

      def subjects_taught
        [
          subjects
        ] + courses
      end

      def teaching_hours
        [
          hours_teaching_eligible_subjects,
          half_teaching_hours
        ]
      end

      def teaching_qualification
        [
          [
            question(:teaching_qualification),
            selected_option(
              :teaching_qualification,
              eligibility.teaching_qualification
            )
          ]
        ]
      end

      def performance_and_disciplinary_measures
        [
          disciplinary_measures,
          performance_measures
        ]
      end

      def policy_options_provided
        [
          [
            I18n.t("further_education_payments.policy_short_name"),
            number_to_currency(eligibility.award_amount, precision: 0)
          ]
        ]
      end

      private

      def current_school
        [
          translate("admin.current_school"),
          display_school(eligibility.current_school)
        ]
      end

      def teaching_responsibilities
        [
          question(:teaching_responsibilities),
          display_boolean(eligibility.teaching_responsibilities)
        ]
      end

      def fe_provider
        [
          question(:further_education_provision_search),
          eligibility.school.name
        ]
      end

      def contract_type
        [
          question(:contract_type, school_name: eligibility.school.name),
          contract_type_answer
        ]
      end

      def teaching_hours_per_week
        [
          question(:teaching_hours_per_week, school_name: eligibility.school.name),
          selected_option(:teaching_hours_per_week, eligibility.teaching_hours_per_week)
        ]
      end

      def subjects
        [
          question(:subjects_taught),
          eligibility.subjects_taught.map { |subject| selected_option(:subjects_taught, subject) }
        ]
      end

      def courses
        eligibility.subjects_taught.map do |subject|
          [
            I18n.t("further_education_payments.forms.#{subject}_courses.question_check_your_answers"),
            course_descriptions_for_subject(subject)
          ]
        end
      end

      def course_descriptions_for_subject(subject)
        eligibility.courses
          .select { |course| course.subject == subject }
          .map(&:description)
          .map(&:html_safe)
      end

      def hours_teaching_eligible_subjects
        [
          question(:hours_teaching_eligible_subjects),
          display_boolean(eligibility.hours_teaching_eligible_subjects)
        ]
      end

      def half_teaching_hours
        [
          question(:half_teaching_hours),
          display_boolean(eligibility.half_teaching_hours)
        ]
      end

      def performance_measures
        [
          question("poor_performance.questions.performance"),
          display_boolean(eligibility.subject_to_formal_performance_action)
        ]
      end

      def disciplinary_measures
        [
          question("poor_performance.questions.disciplinary"),
          display_boolean(eligibility.subject_to_disciplinary_action)
        ]
      end

      def question(attr, **)
        I18n.t("further_education_payments.forms.#{attr}.question", **)
      end

      def selected_option(attr, value)
        I18n.t("further_education_payments.forms.#{attr}.options.#{value}")
      end

      def contract_type_answer
        if eligibility.fixed_contract?
          "Permanent contract (including full-time and part-time contracts)"
        elsif eligibility.contract_type == "variable_hours"
          "Variable hours contract"
        else
          "Fixed term contract"
        end
      end

      def display_boolean(value)
        value ? "Yes" : "No"
      end
    end
  end
end
