module AutomatedChecks
  module ClaimVerifiers
    class Identity
      TASK_NAME = "identity_confirmation".freeze
      private_constant :TASK_NAME

      def initialize(
        claim:,
        dqt_teacher_status:,
        admin_user: nil
      )
        self.admin_user = admin_user
        self.claim = claim
        self.dqt_teacher_status = dqt_teacher_status
      end

      def perform
        return if task_exists?

        if dqt_teacher_status.not_found?
          create_note(body: "[DQT Identity] - Not matched")
          create_task(match: :none)
        else
          notes = []

          unless national_insurance_number_matched?
            notes << create_field_note(
              name: "National Insurance number",
              claimant: claim.national_insurance_number,
              dqt: dqt_teacher_status.national_insurance_number
            )
          end

          unless name_matched?
            notes << create_field_note(
              name: "First name or surname",
              claimant: claim.full_name,
              dqt: "#{dqt_teacher_status.first_name} #{dqt_teacher_status.surname}"
            )
          end

          unless dob_matched?
            notes << create_field_note(
              name: "Date of birth",
              claimant: claim.date_of_birth,
              dqt: dqt_teacher_status.date_of_birth
            )
          end

          unless trn_matched?
            notes << create_field_note(
              name: "Teacher reference number",
              claimant: claim.eligibility.teacher_reference_number,
              dqt: dqt_teacher_status.teacher_reference_number
            )
          end

          if active_alert?
            notes << create_note(
              body: "IMPORTANT: Teacher’s identity has an active alert. Speak to manager before checking this claim.",
              important: true
            )
          end

          if notes.any?
            create_task(match: :any)
          else
            create_task(match: :all, passed: true)
          end
        end
      end

      private

      attr_accessor :admin_user, :claim
      attr_reader :dqt_teacher_status

      def dqt_teacher_status=(dqt_teacher_status)
        @dqt_teacher_status = if dqt_teacher_status.instance_of?(Array)
          dqt_teacher_status.first
        else
          dqt_teacher_status
        end
      end

      def active_alert?
        dqt_teacher_status.active_alert?
      end

      def task_exists?
        claim.tasks.where(name: TASK_NAME).exists?
      end

      def create_field_note(
        name:,
        claimant:,
        dqt:
      )
        body = <<~HTML
          [DQT Identity] - #{name} not matched:
          <pre>
            Claimant: <span class="dark-grey">"</span><span class="red">#{claimant}</span><span class="dark-grey">"</span>
            DQT:      <span class="dark-grey">"</span><span class="green">#{dqt}</span><span class="dark-grey">"</span>
          </pre>
        HTML

        create_note(body: body)
      end

      def create_note(body:, important: false)
        claim.notes.create!(
          {
            body: body,
            label: TASK_NAME,
            created_by: admin_user,
            important: important
          }
        )
      end

      def create_task(match:, passed: nil)
        task = claim.tasks.build(
          {
            name: TASK_NAME,
            claim_verifier_match: match,
            passed: passed,
            manual: false,
            created_by: admin_user
          }
        )

        task.save!(context: :claim_verifier)

        task
      end

      def dob_matched?
        claim.date_of_birth == dqt_teacher_status.date_of_birth
      end

      def name_matched?
        dqt_teacher_status.first_name&.casecmp?(claim.first_name) &&
          dqt_teacher_status.surname&.casecmp?(claim.surname)
      end

      def national_insurance_number_matched?
        claim.national_insurance_number == dqt_teacher_status.national_insurance_number
      end

      def trn_matched?
        claim.eligibility.teacher_reference_number == dqt_teacher_status.teacher_reference_number
      end
    end
  end
end
