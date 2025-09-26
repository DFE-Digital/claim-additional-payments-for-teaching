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

      def provider_verification_rows
        return [] unless provider_verification_submitted?

        [
          [
            "Contract of employment",
            I18n.t(
              eligibility.contract_type,
              scope: "further_education_payments.forms.contract_type.options"
            ),
            provider_answers.contract_type
          ],
          [
            "Teaching responsibilities",
            I18n.t(eligibility.teaching_responsibilities, scope: :boolean),
            provider_answers.teaching_responsibilities
          ],
          [
            "First 5 years of teaching",
            AcademicYear.new(eligibility.further_education_teaching_start_year),
            provider_answers.in_first_five_years
          ],
          [
            "Timetabled teaching hours",
            I18n.t(
              eligibility.teaching_hours_per_week,
              scope: "further_education_payments.forms.teaching_hours_per_week.options"
            ),
            provider_answers.teaching_hours_per_week
          ],
          [
            "Age range taught",
            I18n.t(eligibility.half_teaching_hours, scope: :boolean),
            provider_answers.half_teaching_hours
          ],
          [
            "Subject",
            claimant_subjects_taught.join("<br><br>").html_safe,
            provider_answers.half_timetabled_teaching_time
          ],
          [
            "Course",
            eligibility.courses_taught.map(&:description).join("<br><br>").html_safe,
            provider_answers.half_timetabled_teaching_time
          ],
          [
            "Performance measures",
            I18n.t(eligibility.subject_to_formal_performance_action, scope: :boolean),
            provider_answers.performance_measures
          ],
          [
            "Disciplinary action",
            I18n.t(eligibility.subject_to_disciplinary_action, scope: :boolean),
            provider_answers.disciplinary_action
          ]
        ]
      end

      def student_loan_plan
        [
          ["Student loan plan", claim.student_loan_plan&.humanize]
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
    end
  end
end
