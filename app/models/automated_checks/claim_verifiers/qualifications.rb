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

        complete_match
      end

      private

      attr_accessor :admin_user, :claim, :dqt_teacher_status

      def awaiting_task?(task_name)
        claim.tasks.none? { |task| task.name == task_name }
      end

      def complete_match
        return unless claim.policy::DqtRecord.new(dqt_teacher_status).eligible?

        create_passed_task
      end

      def create_passed_task
        claim.tasks.create!(
          {
            name: "qualifications",
            passed: true,
            manual: false,
            created_by: admin_user
          }
        )
      end

      def tasks=(tasks)
        @tasks = tasks.map { |task| task.new(self) }
      end
    end
  end
end
