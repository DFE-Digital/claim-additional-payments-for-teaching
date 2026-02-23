module Admin
  module Amendments
    class FurtherEducationPaymentsForm < Admin::AmendmentForm
      attribute :further_education_teaching_start_year, :string

      def load_data_from_claim
        super

        self.further_education_teaching_start_year = eligibility.further_education_teaching_start_year
      end

      def save
        fe_start_year_changes = change_hash["further_education_teaching_start_year"]

        super

        if existing_provider_verification_task.present? && fe_start_year_changes.present?
          rerun_provider_verification_task(fe_start_year_changes)
        end

        true
      end

      private

      def existing_provider_verification_task
        @existing_provider_verification_task ||=
          claim.tasks.find_by(name: "fe_provider_verification_v2")
      end

      def rerun_provider_verification_task(fe_start_year_changes)
        original_start_year, _ = fe_start_year_changes
        ApplicationRecord.transaction do
          note_body = <<~TEXT.squish
            This task was previously
            #{existing_provider_verification_task.passed? ? "passed" : "failed"}
            by an automated check on #{existing_provider_verification_task.created_at}.
            The further_education_teaching_start_year was changed by an amendment
            so this task was rerun.
            The original further_education_teaching_start_year was
            #{original_start_year}
          TEXT

          existing_provider_verification_task.destroy!
          claim.reload
          AutomatedChecks::ClaimVerifiers::FeProviderVerificationV2.new(claim).perform

          claim.notes.create!(
            label: "fe_provider_verification_v2",
            body: note_body
          )
        end
      end
    end
  end
end
