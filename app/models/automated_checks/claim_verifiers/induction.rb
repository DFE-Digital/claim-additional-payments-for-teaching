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
        return unless claim.policy == Policies::EarlyCareerPayments
        return unless awaiting_task?

        no_data || no_match || matched
      end

      private

      attr_accessor :admin_user, :claim
      attr_reader :dqt_teacher_status

      delegate :itt_year, :induction_status, :induction_start_date, :induction_completion_date, to: :dqt_teacher_status
      delegate :eligible?, :incomplete?, to: :induction_data

      def induction_data
        @induction_data ||= Policies::EarlyCareerPayments::InductionData.new(itt_year:, induction_status:, induction_start_date:)
      end

      def awaiting_task?
        claim.tasks.where(name: TASK_NAME).count.zero?
      end

      def no_data
        return if dqt_teacher_status.present? && !incomplete?

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
        header = if match.nil?
          "[DQT Induction] - No data"
        else
          "[DQT Induction] - #{(match == :none) ? "Ineligible" : "Eligible"}"
        end

        body = if dqt_teacher_status.present?
          <<~HTML
            #{header}:
            <pre>
              Start date:      #{induction_start_date || "N/A"}
              Completion date: #{induction_completion_date || "N/A"}
              Status:          #{induction_status || "N/A"}
            </pre>
          HTML
        else
          header
        end

        claim.notes.create!(
          {
            body: body,
            label: TASK_NAME,
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
