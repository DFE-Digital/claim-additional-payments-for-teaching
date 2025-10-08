module Policies
  module FurtherEducationPayments
    class AdminTasksPresenter
      attr_reader :claim, :eligibility

      def initialize(claim)
        @claim = claim
        @eligibility = claim.eligibility
      end

      def provider_verification_submitted?
        eligibility.provider_verification_completed_at.present?
      end

      def provider_name
        eligibility.provider_assigned_to&.full_name || "Not assigned"
      end

      def provider_email
        eligibility.provider_assigned_to&.email || "Not assigned"
      end

      def provider_verification_rows
        return [] unless provider_verification_submitted?

        rows = [
          teaching_responsibilities,
          first_five_years_of_teaching,
          teaching_qualification,
          reason_for_not_enrolling,
          contract_of_employment,
          performance_measure,
          disciplinary_action,
          timetabled_teaching_hours
        ]

        # Conditional: Hours per week next term (variable hours only)
        if eligibility.provider_verification_contract_type == "variable_hours"
          rows << teaching_hours_per_week_next_term
        end

        # Conditional: Contract covers full year (fixed term only)
        if eligibility.provider_verification_contract_type == "fixed_term"
          rows << contract_covers_full_academic_year
        end

        rows += [
          age_range_taught,
          subject,
          course
        ]

        # Conditional: Taught at least one term (variable hours only)
        if eligibility.provider_verification_contract_type == "variable_hours"
          rows << taught_at_least_one_academic_term
        end

        rows << continued_employment

        rows.compact_blank
      end

      def student_loan_plan
        [
          ["Student loan plan", claim.student_loan_plan&.humanize]
        ]
      end

      def provider_details
        [
          ["Provider name", provider_name],
          ["Provider email", provider_email],
          ["Claimant name", claim.full_name],
          ["Claimant email", claim.email_address]
        ]
      end

      private

      def provider_answers
        @provider_answers ||= ::FurtherEducationPayments::Providers::Claims::Verification::CheckAnswersForm.new(
          claim: claim,
          user: nil
        )
      end

      def claimant_subjects_taught
        claim.eligibility.subjects_taught.map do |subject|
          I18n.t(
            [
              "further_education_payments",
              "forms",
              "subjects_taught",
              "options",
              subject
            ].join(".")
          )
        end
      end

      def contract_of_employment
        [
          "Contract of employment",
          I18n.t(
            eligibility.contract_type,
            scope: "further_education_payments.forms.contract_type.options"
          ),
          provider_answers.contract_type
        ]
      end

      def teaching_qualification
        claimant_value = case eligibility.teaching_qualification
        when "yes"
          "Yes"
        when "not_yet"
          "Not yet, I am currently enrolled on one and working towards completing it"
        when "no_but_planned"
          "No, but I plan to enrol on one in the next 12 months"
        when "no_not_planned"
          "No, and I do not plan to enrol on one in the next 12 months"
        else
          "Not provided"
        end

        [
          "Teaching qualification",
          claimant_value,
          provider_answers.teaching_qualification
        ]
      end

      def teaching_hours_per_week_next_term
        [
          "Hours per week next term",
          "Not provided",  # Claimant doesn't answer this question
          provider_answers.teaching_hours_per_week.present? ? provider_answers.teaching_hours_per_week : "Not answered"
        ]
      end

      def contract_covers_full_academic_year
        [
          "Contract covers full academic year",
          I18n.t(eligibility.fixed_term_full_year, scope: :boolean),
          provider_answers.contract_covers_full_academic_year
        ]
      end

      def taught_at_least_one_academic_term
        [
          "Taught at least one academic term",
          I18n.t(eligibility.taught_at_least_one_term, scope: :boolean),
          provider_answers.taught_at_least_one_academic_term
        ]
      end

      def teaching_responsibilities
        [
          "Teaching responsibilities",
          I18n.t(eligibility.teaching_responsibilities, scope: :boolean),
          provider_answers.teaching_responsibilities
        ]
      end

      def first_five_years_of_teaching
        start_year = eligibility.further_education_teaching_start_year.to_i
        formatted_date = "#{start_year}/#{start_year + 1}"

        [
          "First 5 years of teaching",
          formatted_date,
          provider_answers.in_first_five_years
        ]
      end

      def reason_for_not_enrolling
        return [] if eligibility.provider_verification_not_started_qualification_reasons.empty?

        reason = if eligibility.valid_reason_for_not_starting_qualification?
          "Valid reason"
        else
          "No valid reason"
        end

        [
          "Reason for not enrolling",
          "N/A",
          reason
        ]
      end

      def timetabled_teaching_hours
        claimant_mapped = case eligibility.teaching_hours_per_week
        when "more_than_12"
          "20 hours or more each week"
        when "between_2_5_and_12"
          "2.5 to 12 hours each week"
        when "less_than_2_5"
          "Fewer than 2.5 hours each week"
        else
          I18n.t(
            eligibility.teaching_hours_per_week,
            scope: "further_education_payments.forms.teaching_hours_per_week.options"
          )
        end

        [
          "Timetabled teaching hours",
          claimant_mapped,
          provider_answers.teaching_hours_per_week
        ]
      end

      def age_range_taught
        [
          "Age range taught",
          I18n.t(eligibility.half_teaching_hours, scope: :boolean),
          provider_answers.half_teaching_hours
        ]
      end

      def subject
        [
          "Subject",
          claimant_subjects_taught.join("<br><br>").html_safe,
          provider_answers.half_timetabled_teaching_time
        ]
      end

      def course
        [
          "Course",
          eligibility.courses_taught.map(&:description).join("<br><br>").html_safe,
          provider_answers.half_timetabled_teaching_time
        ]
      end

      def performance_measure
        [
          "Subject to performance measures",
          I18n.t(eligibility.subject_to_formal_performance_action, scope: :boolean),
          provider_answers.performance_measures
        ]
      end

      def disciplinary_action
        [
          "Subject to disciplinary action",
          I18n.t(eligibility.subject_to_disciplinary_action, scope: :boolean),
          provider_answers.disciplinary_action
        ]
      end

      def continued_employment
        [
          "Continued employment",
          "N/A",
          provider_answers.continued_employment
        ]
      end
    end
  end
end
