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

        complete_match ||
          partial_match ||
          no_match
      end

      private

      attr_accessor :admin_user, :claim, :dqt_teacher_status

      def awaiting_task?(task_name)
        claim.tasks.none? { |task| task.name == task_name }
      end

      def complete_match
        return unless trn_matched? &&
          national_insurance_number_matched? &&
          name_matched? &&
          dob_matched?

        create_passed_task
      end

      def create_note(field_body = nil)
        claim.notes.create!(
          {
            body: "#{field_body ? field_body + " n" : "N"}ot matched",
            created_by: admin_user
          }
        )
      end

      def create_passed_task
        claim.tasks.create!(
          {
            name: "identity_confirmation",
            passed: true,
            manual: false,
            created_by: admin_user
          }
        )
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

      def no_match
        return unless !trn_matched? && !national_insurance_number_matched?

        ClaimMailer.identity_confirmation(claim).deliver_later

        create_note
      end

      def partial_match
        if trn_matched? && name_matched? && dob_matched?
          create_note("National Insurance number")

          return create_passed_task
        end

        if trn_matched? && national_insurance_number_matched? && dob_matched?
          create_note("First name or surname")

          return create_passed_task
        end

        if trn_matched? && national_insurance_number_matched? && name_matched?
          create_note("Date of birth")

          return create_passed_task
        end

        if national_insurance_number_matched? && name_matched? & dob_matched?
          create_note("Teacher reference number")
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
