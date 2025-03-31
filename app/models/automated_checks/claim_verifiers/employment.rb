module AutomatedChecks
  module ClaimVerifiers
    class Employment
      TASK_NAME = "employment".freeze
      private_constant :TASK_NAME

      def initialize(claim:, admin_user: nil)
        self.admin_user = admin_user
        self.claim = claim
        self.teachers_pensions_service = TeachersPensionsService.by_teacher_reference_number(claim.eligibility.teacher_reference_number)
      end

      def perform
        return unless required?
        return unless awaiting_task?

        no_data || no_match || matched
      end

      private

      def required?
        claim.eligibility.teacher_reference_number.present?
      end

      attr_accessor :admin_user, :claim, :teachers_pensions_service

      def awaiting_task?
        claim.tasks.where(name: TASK_NAME).count.zero?
      end

      def teachers_pensions_service_schools
        return [] if teachers_pensions_service.empty?

        @teachers_pensions_service_schools ||= begin
          from = claim.submitted_at.beginning_of_month.prev_month
          to = claim.submitted_at.end_of_month

          teachers_pensions_service
            .between_claim_dates(from, to)
            .map { |r| [r.la_urn, r.school_urn] }
            .uniq
        end
      end

      def teachers_pensions_service_claim_schools
        return [] unless teachers_pensions_service.any? && claim.policy == Policies::StudentLoans

        @teachers_pensions_service_claim_schools ||= begin
          latest_start_date = end_of_previous_financial_year - 1.month
          earliest_end_date = start_of_previous_financial_year + 1.month

          teachers_pensions_service
            .claim_dates_interval(latest_start_date, earliest_end_date)
            .map { |r| [r.la_urn, r.school_urn] }
            .uniq
        end
      end

      def start_of_previous_financial_year
        previous_academic_year = Policies::StudentLoans.current_academic_year - 1
        Date.new(previous_academic_year.start_year, 4, 6)
      end

      def end_of_previous_financial_year
        Date.new(Policies::StudentLoans.current_academic_year.start_year, 4, 5)
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
        eligible_current_school = eligible_school?(teachers_pensions_service_schools, claim.eligibility.current_school)

        return eligible_current_school unless claim.policy == Policies::StudentLoans && eligible_current_school

        eligible_school?(teachers_pensions_service_claim_schools, claim.eligibility.claim_school)
      end

      def eligible_school?(tps_schools, school)
        tps_schools.select do |code, establishment_number|
          school.local_authority.code == code && school.establishment_number == establishment_number
        end.any?
      end

      def create_task(match:, passed: nil)
        task = claim.tasks.find_or_initialize_by(name: TASK_NAME)
        task.claim_verifier_match = match
        task.passed = passed
        task.manual = false
        task.created_by = admin_user

        task.save!(context: :claim_verifier)

        create_note(match: match)

        task
      end

      def create_note(match:)
        body = if teachers_pensions_service.empty?
          "[Employment] - No data"
        else
          schools_details = ""
          teachers_pensions_service_schools.each do |school|
            schools_details += "Current school: LA Code: #{school[0]} / Establishment Number: #{school[1]}\n"
          end

          teachers_pensions_service_claim_schools.each do |school|
            schools_details += "Claim school: LA Code: #{school[0]} / Establishment Number: #{school[1]}\n"
          end

          <<~HTML
            [Employment] - #{(match == :none) ? "Ine" : "E"}ligible:
            <pre>#{schools_details}</pre>
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
    end
  end
end
