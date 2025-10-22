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

        [
          teaching_responsibilities,
          first_five_years_of_teaching,
          teaching_qualification,
          reason_for_not_enrolling,
          contract_of_employment,
          timetabled_teaching_hours,
          age_range_taught,
          subject,
          course,
          performance_measure,
          disciplinary_action,
          continued_employment
        ].compact_blank
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

      def teaching_responsibilities
        [
          "Teaching responsibilities",
          I18n.t(eligibility.teaching_responsibilities, scope: :boolean),
          provider_answers.teaching_responsibilities
        ]
      end

      def first_five_years_of_teaching
        [
          "First 5 years of teaching",
          AcademicYear.new(eligibility.further_education_teaching_start_year),
          provider_answers.in_first_five_years
        ]
      end

      def teaching_qualification
        [
          "Teaching qualification",
          I18n.t(
            eligibility.teaching_qualification,
            scope: "further_education_payments.forms.teaching_qualification.options"
          ),
          provider_answers.teaching_qualification
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
        [
          "Timetabled teaching hours",
          I18n.t(
            eligibility.teaching_hours_per_week,
            scope: "further_education_payments.forms.teaching_hours_per_week.options"
          ),
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
          "Performance measures",
          I18n.t(eligibility.subject_to_formal_performance_action, scope: :boolean),
          provider_answers.performance_measures
        ]
      end

      def disciplinary_action
        [
          "Disciplinary action",
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
