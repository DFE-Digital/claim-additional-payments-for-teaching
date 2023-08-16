module AutomatedChecks
  module ClaimVerifiers
    class Induction
      TASK_NAME = "induction_confirmation".freeze
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
        return unless claim.policy == EarlyCareerPayments
        return unless awaiting_task?

        no_data || no_match || matched
      end

      private

      attr_accessor :admin_user, :claim
      attr_reader :dqt_teacher_status

      def awaiting_task?
        claim.tasks.where(name: TASK_NAME).count.zero?
      end

      def no_data
        return if dqt_teacher_status.present?

        create_task(match: nil)
      end

      def no_match
        return if eligible?

        create_task(match: :none)
      end

      def matched
        return unless eligible?

        create_task(match: :all, passed: true)
      end

      def eligible?
        dqt_teacher_status.eligible_induction?
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

        create_note(match: match)

        task
      end

      def create_note(match:)
        body = if dqt_teacher_status.nil?
          "[DQT Induction] - No data"
        else
          <<~HTML
            [DQT Induction] - #{(match == :none) ? "Ine" : "E"}ligible:
            <pre>
              Start date:      #{dqt_teacher_status.induction_start_date || "N/A"}
              Completion date: #{dqt_teacher_status.induction_completion_date || "N/A"}
              Status:          #{dqt_teacher_status.induction_status || "N/A"}
            </pre>
          HTML
        end

        claim.notes.create!(
          {
            body: body,
            created_by: admin_user
          }
        )
      end

      def dqt_teacher_status=(dqt_teacher_status)
        return if dqt_teacher_status.nil?

        dqt_teacher_status = if dqt_teacher_status.instance_of?(Array)
          dqt_teacher_status.first
        else
          dqt_teacher_status
        end

        @dqt_teacher_status = claim.policy::DqtRecord.new(dqt_teacher_status, claim)
      end
    end
  end
end
