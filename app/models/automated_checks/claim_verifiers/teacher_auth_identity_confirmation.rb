module AutomatedChecks
  module ClaimVerifiers
    class TeacherAuthIdentityConfirmation
      TASK_NAME = "teacher_auth_identity_confirmation"

      def initialize(claim:)
        @claim = claim
        @eligibility = claim.eligibility
      end

      def perform
        return if claim.tasks.teacher_auth_identity_confirmation.exists?

        notes = []

        unless national_insurance_number_matched?
          notes << create_field_note(
            field: "National insurance number",
            claimant: claim.national_insurance_number,
            teacher_auth: eligibility.teacher_auth_national_insurance_number
          )
        end

        if Dqt::Teacher.new(claim.dqt_teacher_status).active_alert?
          notes << claim.notes.create!(
            label: TASK_NAME,
            body: "IMPORTANT: Teacher’s identity has an active alert. Speak to manager before checking this claim.",
            important: true
          )
        end

        task = if notes.any?
          claim.tasks.build(
            name: TASK_NAME,
            claim_verifier_match: :any,
            passed: nil,
            manual: false
          )
        else
          claim.tasks.build(
            name: TASK_NAME,
            claim_verifier_match: :all,
            passed: true,
            manual: false
          )
        end

        task.save!(context: :claim_verifier)

        task
      end

      private

      attr_reader :claim, :eligibility

      def national_insurance_number_matched?
        claim.national_insurance_number == eligibility.teacher_auth_national_insurance_number
      end

      def create_field_note(field:, claimant:, teacher_auth:)
        body = <<~HTML
          [Teacher Auth Identity] - #{field} not matched:
          <pre>
            Claimant:     <span class="dark-grey">"</span><span class="red">#{claimant}</span><span class="dark-grey">"</span>
            Teacher Auth: <span class="dark-grey">"</span><span class="green">#{teacher_auth}</span><span class="dark-grey">"</span>
          </pre>
        HTML

        claim.notes.create!(label: TASK_NAME, body: body)
      end
    end
  end
end
