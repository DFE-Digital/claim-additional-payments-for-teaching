module AutomatedChecks
  module ClaimVerifiers
    class EyQualificationCheck
      TASK_NAME = "qualifications"

      def initialize(claim:)
        @claim = claim
      end

      def perform
        return if task_exists?

        # Task always passes as only those with the expected teacher status can
        # complete the journey.
        task = claim.tasks.build(
          name: TASK_NAME,
          passed: true,
          manual: false
        )

        ApplicationRecord.transaction do
          task.save!(context: :claim_verifier)
          create_note
        end
      end

      private

      attr_reader :claim

      def task_exists?
        claim.tasks.where(name: TASK_NAME).exists?
      end

      def create_note
        return nil unless claim.has_dqt_record?

        claim.notes.create!(
          {
            body: note_body,
            label: TASK_NAME
          }
        )
      end

      def note_body
        html = []
        html << "[DQT Qualifications]"

        dqt_teacher_status_object.routes_to_professional_statuses.each do |route|
          html << "<pre>"
          html << "Qualification name: #{route["routeToProfessionalStatusType"]["name"]}"
          html << "Qualification status: #{route["status"]}"
          html << "Qualification start date: #{route["trainingStartDate"]}"
          html << "Qualification award date: #{route["holdsFrom"]}"
          html << "</pre>"
        end

        html.join("\n")
      end

      def dqt_teacher_status_object
        @dqt_teacher_status_object ||= Dqt::Teacher.new(claim.dqt_teacher_status)
      end
    end
  end
end
