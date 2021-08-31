module AutomatedChecks
  module ClaimVerifiers
    class Qualifications
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
        return unless awaiting_task?("qualifications")

        # Order matters so that subsequent conditions in methods fall through to execute the right thing
        no_match ||
          complete_match ||
          partial_match
      end

      private

      attr_accessor :admin_user, :claim
      attr_reader :dqt_teacher_status

      def awaiting_task?(task_name)
        claim.tasks.none? { |task| task.name == task_name }
      end

      def complete_match
        return unless dqt_teacher_status.eligible?

        create_task(match: :all, passed: true)
      end

      def create_note(field_body = nil)
        claim.notes.create!(
          {
            body: "#{field_body ? field_body + " n" : "N"}ot eligible",
            created_by: admin_user
          }
        )
      end

      def create_task(match:, passed: nil)
        task = claim.tasks.build(
          {
            name: "qualifications",
            claim_verifier_match: match,
            passed: passed,
            manual: false,
            created_by: admin_user
          }
        )

        task.save!(context: :claim_verifier)

        task
      end

      def dqt_teacher_status=(dqt_teacher_status)
        return if dqt_teacher_status.nil?

        @dqt_teacher_status = claim.policy::DqtRecord.new(dqt_teacher_status, claim)
      end

      def no_match
        return unless dqt_teacher_status.nil? ||
          (
            !dqt_teacher_status.eligible_qts_date? &&
            !dqt_teacher_status.eligible_qualification_subject?
          )

        create_note
        create_task(match: :none)
      end

      def partial_match
        if dqt_teacher_status.eligible_qts_date?
          create_note("ITT subject codes")

          return create_task(match: :any)
        end

        if dqt_teacher_status.eligible_qualification_subject?
          create_note("QTS award date")
          create_task(match: :any)
        end
      end

      def tasks=(tasks)
        @tasks = tasks.map { |task| task.new(self) }
      end
    end
  end
end
