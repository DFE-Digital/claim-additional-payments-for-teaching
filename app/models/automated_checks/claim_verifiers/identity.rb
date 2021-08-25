module AutomatedChecks
  module ClaimVerifiers
    class Identity
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
        return unless awaiting_task?("identity_confirmation")

        # Order of matching matters so that subsequent conditions in methods fall through to execute the right thing
        no_match ||
          partial_match ||
          complete_match
      end

      private

      attr_accessor :admin_user, :claim, :dqt_teacher_status

      def active_alert?
        dqt_teacher_status[:active_alert]
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
        id_matched_note
      end

      def create_field_note(name:)
        body = "#{name} not matched"

        create_note(body: body)
      end

      def create_note(body:, important: false)
        claim.notes.create!(
          {
            body: body,
            created_by: admin_user,
            important: important
          }
        )
      end

      def create_task(match:, passed: nil)
        task = claim.tasks.build(
          {
            name: "identity_confirmation",
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
        claim.date_of_birth == dqt_teacher_status.fetch(:date_of_birth)
      end

      def name_matched?
        dqt_teacher_status.fetch(:first_name)&.casecmp?(claim.first_name) &&
          dqt_teacher_status.fetch(:surname)&.casecmp?(claim.surname)
      end

      def national_insurance_number_matched?
        claim.national_insurance_number == dqt_teacher_status.fetch(:national_insurance_number)
      end

      def id_matched_note
        create_note(body: "Claimant inputted value: Name: #{claim.first_name} #{claim.surname}, NIN: #{claim.national_insurance_number}, DOB: #{claim.date_of_birth}")
        if name_matched? && !national_insurance_number_matched?
          create_note(body: "Name returned from DQT: #{dqt_teacher_status.fetch(:first_name) || ""} #{dqt_teacher_status.fetch(:surname) || ""}, National Insurance number not matched, DOB: #{dqt_teacher_status.fetch(:date_of_birth) || "DOB not found"}")
        elsif name_matched? && national_insurance_number_matched? && dob_matched?
          create_note(body: "Name returned from DQT: #{dqt_teacher_status.fetch(:first_name) || ""} #{dqt_teacher_status.fetch(:surname) || ""}, NIN: #{dqt_teacher_status.fetch(:national_insurance_number) || ""} DOB: #{dqt_teacher_status.fetch(:date_of_birth) || " "}")
        else
          create_note(body: "No details found in DQT for claimant inputted value")
        end
      end

      def no_match
        return unless dqt_teacher_status.nil?

        ClaimMailer.identity_confirmation(claim).deliver_later

        create_note(body: "Not matched")
        id_matched_note
        create_task(match: :none)
      end

      def partial_match
        if !national_insurance_number_matched?
          create_field_note(name: "National Insurance number")
          id_matched_note

          return create_task(match: :any)
        end

        if !name_matched?
          create_field_note(name: "First name or surname")

          return create_task(match: :any)
        end

        if !dob_matched?
          create_field_note(name: "Date of birth")

          return create_task(match: :any)
        end

        if !trn_matched?
          create_field_note(name: "Teacher reference number")

          return create_task(match: :any)
        end

        if active_alert?
          create_note(body: "IMPORTANT: Teacher’s identity has an active alert. Speak to manager before checking this claim.", important: true)

          create_task(match: :any)
        end
      end

      def tasks=(tasks)
        @tasks = tasks.map { |task| task.new(self) }
      end

      def trn_matched?
        claim.teacher_reference_number == dqt_teacher_status.fetch(:teacher_reference_number)
      end
    end
  end
end
