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
        return unless awaiting_task?(TASK_NAME)

        if claim.identity_confirmed_with_onelogin?
          one_login
        elsif claim.onelogin_idv_at.present? && !claim.identity_confirmed_with_onelogin?
          # noop
          # TODO: tbd what happens when OL user that fails OL idv comes thru
        else
          # Order of matching matters so that subsequent conditions in methods fall through to execute the right thing
          no_match || partial_match || complete_match
        end
      end

      private

      attr_accessor :admin_user, :claim
      attr_reader :dqt_teacher_status

      def one_login
        if claim.one_login_idv_mismatch?
          create_task(match: nil, passed: false)
        else
          create_task(match: nil, passed: true)
        end
      end

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

      def awaiting_task?(task_name)
        claim.tasks.none? { |task| task.name == task_name }
      end

      def complete_match
        return unless trn_matched? &&
          national_insurance_number_matched? &&
          name_matched? &&
          dob_matched? &&
          !active_alert?

        create_task(match: :all, passed: true)
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

      def no_match
        return unless dqt_teacher_status.nil?

        create_note(body: "[DQT Identity] - Not matched")
        create_task(match: :none)
      end

      def partial_match
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

        notes << create_note(body: "IMPORTANT: Teacher’s identity has an active alert. Speak to manager before checking this claim.", important: true) if active_alert?

        create_task(match: :any) if notes.any?
      end

      def tasks=(tasks)
        @tasks = tasks.map { |task| task.new(self) }
      end

      def trn_matched?
        claim.eligibility.teacher_reference_number == dqt_teacher_status.teacher_reference_number
      end
    end
  end
end
