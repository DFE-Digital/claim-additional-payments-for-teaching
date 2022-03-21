module AutomatedChecks
  module ClaimVerifiers
    class Employment
      def initialize(
        claim:,
        admin_user: nil
      )
        self.admin_user = admin_user
        self.claim = claim
        self.teachers_pensions_service = TeachersPensionsService.by_teacher_reference_number(claim.teacher_reference_number)
        self.teachers_pensions_service_schools = teachers_pensions_service
      end

      def perform
        return unless awaiting_task?("employment")

        no_data || no_match || matched
      end

      private

      attr_accessor :admin_user, :claim, :teachers_pensions_service
      attr_reader :teachers_pensions_service_schools

      def awaiting_task?(task_name)
        claim.tasks.none? { |task| task.name == task_name }
      end

      def teachers_pensions_service_schools=(teachers_pensions_service)
        return if teachers_pensions_service.empty?

        @teachers_pensions_service_schools = teachers_pensions_service.between_claim_dates(
          claim.submitted_at.beginning_of_month.prev_month,
          claim.submitted_at.end_of_month
        ).map { |r| [r.la_urn, r.school_urn] }.uniq
      end

      def no_data
        return unless teachers_pensions_service.empty?

        create_task(match: nil)
      end

      def no_match
        return unless teachers_pensions_service.empty? || !eligible?

        create_task(match: :none)
      end

      def matched
        return unless eligible?

        create_task(match: :all, passed: true)
      end

      def eligible?
        teachers_pensions_service_schools.select do |code, establishment_number|
          claim.eligibility.current_school.local_authority.code == code && claim.eligibility.current_school.establishment_number == establishment_number
        end.any?
      end

      def create_task(match:, passed: nil)
        task = claim.tasks.build(
          {
            name: "employment",
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
        body = if teachers_pensions_service.empty?
          "[Employment] - No data"
        else
          schools_details = ""
          teachers_pensions_service_schools.each_with_index do |school, idx|
            schools_details += "School #{idx + 1}: LA Code: #{school[0]} / Establishment Number: #{school[1]}\n"
          end

          <<~HTML
            [Employment] - #{match == :none ? "Ine" : "E"}ligible:
            <pre>#{schools_details}</pre>
          HTML
        end

        claim.notes.create!(
          {
            body: body,
            created_by: admin_user
          }
        )
      end
    end
  end
end
