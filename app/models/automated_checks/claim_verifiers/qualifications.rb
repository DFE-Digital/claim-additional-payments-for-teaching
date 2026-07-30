module AutomatedChecks
  module ClaimVerifiers
    class Qualifications
      TASK_NAME = "qualifications".freeze
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

        if dqt_teacher_status.nil? || !dqt_teacher_status.eligible?
          create_task(match: :none)
        else
          create_task(match: :all, passed: true)
        end
      end

      private

      attr_accessor :admin_user, :claim
      attr_reader :dqt_teacher_status

      def task_exists?
        claim.tasks.where(name: TASK_NAME).exists?
      end

      def create_note(match:)
        body = if dqt_teacher_status.nil?
          "[DQT Qualification] - Not eligible"
        else
          <<~HTML
            [DQT Qualification] - #{(match == :none) ? "Ineligible:" : "Eligible:"}
            <pre>
              ITT subjects: #{dqt_teacher_status.itt_subjects}
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
            label: TASK_NAME,
            created_by: admin_user
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

        ApplicationRecord.transaction do
          task.save!(context: :claim_verifier)
          create_note(match: match)
        end

        task
      end

      def dqt_teacher_status=(dqt_teacher_status)
        return if dqt_teacher_status.nil?

        dqt_teacher_status = if dqt_teacher_status.instance_of?(Array)
          dqt_teacher_status.first
        else
          dqt_teacher_status
        end

        @dqt_teacher_status = claim.policy::DqtRecord.new(dqt_teacher_status, claim.eligibility)
      end
    end
  end
end
