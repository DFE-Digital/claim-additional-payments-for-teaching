module AutomatedChecks
  module ClaimVerifiers
    class Employment
      TASK_NAME = "employment".freeze
      private_constant :TASK_NAME

      def initialize(claim:, admin_user: nil)
        self.admin_user = admin_user
        self.claim = claim
      end

      def perform
        return unless required?
        return if task.has_result?

        if claimant_tps_records.empty?
          create_task(match: nil)
        elsif claimant_tps_records.empty? || !eligible?
          create_task(match: :none)
        else
          create_task(match: :all, passed: true)
        end
      end

      private

      attr_accessor :admin_user, :claim

      def required?
        claim.eligibility.teacher_reference_number.present?
      end

      def awaiting_task?
        claim.tasks.where(name: TASK_NAME).count.zero?
      end

      def start_of_previous_financial_year
        previous_academic_year = Policies::StudentLoans.current_academic_year - 1
        Date.new(previous_academic_year.start_year, 4, 6)
      end

      def end_of_previous_financial_year
        Date.new(Policies::StudentLoans.current_academic_year.start_year, 4, 5)
      end

      def eligible?
        if claim.policy == Policies::StudentLoans
          worked_at_eligible_school_during_month_of_making_claim? &&
            worked_at_eligible_school_during_previous_financial_year?
        else
          worked_at_eligible_school_during_month_of_making_claim?
        end
      end

      def worked_at_eligible_school_during_month_of_making_claim?
        school_during_claim_month = claim.eligibility.current_school

        tps_records_during_month_of_claim.any? do |tps_record|
          tps_record.for_school?(school_during_claim_month)
        end
      end

      def tps_records_during_month_of_claim
        previous_month_start = claim.submitted_at.beginning_of_month.prev_month
        end_of_month = claim.submitted_at.end_of_month

        claimant_tps_records.covering_dates(previous_month_start, end_of_month)
      end

      def worked_at_eligible_school_during_previous_financial_year?
        school_during_previous_financial_year = claim.eligibility.claim_school

        tps_records_during_previous_financial_year.any? do |tps_record|
          tps_record.for_school?(school_during_previous_financial_year)
        end
      end

      def tps_records_during_previous_financial_year
        claimant_tps_records.covering_dates(
          start_of_previous_financial_year,
          end_of_previous_financial_year
        )
      end

      def claimant_tps_records
        TeachersPensionsService.where(
          teacher_reference_number: claim.eligibility.teacher_reference_number
        )
      end

      def task
        @task ||= claim.tasks.find_or_initialize_by(name: TASK_NAME)
      end

      def create_task(match:, passed: nil)
        task.claim_verifier_match = match
        task.passed = passed
        task.manual = false
        task.created_by = admin_user

        ApplicationRecord.transaction do
          task.save!(context: :claim_verifier)
          create_note(match: match)
        end

        task
      end

      def note_body(match:)
        return "[Employment] - No data" if match.nil?

        notes = []

        uniq_tps_schools_in_month_of_claim = tps_records_during_month_of_claim
          .uniq { |tps_record| [tps_record.la_urn, tps_record.school_urn] }

        uniq_tps_schools_in_month_of_claim.each do |tps_record|
          notes << "Current school: LA Code: #{tps_record.la_urn} / Establishment Number: #{tps_record.school_urn}"
          notes << employment_dates_copy_for_tps_record(tps_record)
        end

        if claim.policy == Policies::StudentLoans
          uniq_tps_schools_in_previous_financial_year = tps_records_during_previous_financial_year
            .uniq { |tps_record| [tps_record.la_urn, tps_record.school_urn] }

          uniq_tps_schools_in_previous_financial_year.each do |tps_record|
            notes << "Claim school: LA Code: #{tps_record.la_urn} / Establishment Number: #{tps_record.school_urn}"
            notes << employment_dates_copy_for_tps_record(tps_record)
          end
        end

        eligible_state = ((match == :all) ? "Eligible" : "Ineligible")

        prefix = "[Employment] - #{eligible_state}:"

        schools_details = notes.join("\n")

        <<~HTML
          #{prefix}
          <pre>#{schools_details}\n</pre>
        HTML
      end

      def employment_dates_copy_for_tps_record(tps_record)
        start_date_text = tps_record.start_date.present? ? I18n.l(tps_record.start_date.to_date) : "unknown start date"
        end_date_text = tps_record.end_date.present? ? I18n.l(tps_record.end_date.to_date) : "unknown end date"

        "Employment dates: #{start_date_text} to #{end_date_text}"
      end

      def create_note(match:)
        claim.notes.create!(
          {
            body: note_body(match: match),
            label: TASK_NAME,
            created_by: admin_user
          }
        )
      end
    end
  end
end
