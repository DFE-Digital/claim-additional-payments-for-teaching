module AutomatedChecks
  module ClaimVerifiers
    class Qualifications
      def initialize(
        claim:,
        dqt_teacher_statuses:,
        admin_user: nil
      )
        self.admin_user = admin_user
        self.claim = claim
        self.dqt_teacher_status = dqt_teacher_statuses&.first
      end

      def perform
        return unless awaiting_task?("qualifications")

        no_match || complete_match
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

      def create_note(match:)
        body = if dqt_teacher_status.nil?
          "Not eligible"
        else
          <<~HTML
            #{match == :none ? "Ine" : "E"}ligible:
            <pre>
              ITT subject codes:  #{dqt_teacher_status.itt_subject_codes}
              Degree codes:       #{dqt_teacher_status.degree_codes}
              ITT start date:     #{dqt_teacher_status.itt_start_date}
              QTS award date:     #{dqt_teacher_status.qts_award_date}
              Qualification name: #{dqt_teacher_status.qualification_name}
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

        create_note(match: match)

        task
      end

      def dqt_teacher_status=(dqt_teacher_status)
        return if dqt_teacher_status.nil?

        @dqt_teacher_status = claim.policy::DqtRecord.new(dqt_teacher_status, claim)
      end

      def no_match
        return unless dqt_teacher_status.nil? || !dqt_teacher_status.eligible?

        create_task(match: :none)
      end

      def tasks=(tasks)
        @tasks = tasks.map { |task| task.new(self) }
      end
    end
  end
end
