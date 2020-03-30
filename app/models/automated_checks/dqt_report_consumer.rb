module AutomatedChecks
  # Used to ingest a report from DQT (Database of Qualified Teachers)
  # containing qualification data such as QTS (Qualified Teacher Status)
  # award date, ITT (Initial Teacher Training) subjects and
  # post graduate degree subject.
  #
  # The records will be used to determine if a claimant's qualifications
  # make them eligible for a specific policy.
  class DQTReportConsumer
    attr_reader :csv, :completed_tasks, :total_records

    def initialize(file, admin_user)
      @csv = DQTReportCsv.new(file)
      @admin_user = admin_user
      @completed_tasks = 0
    end

    def ingest
      return if errors.any?

      ActiveRecord::Base.transaction do
        claims = Claim.awaiting_task("qualifications")
        records = DQTReportCsvToRecords.new(csv.rows).transform
        records.each do |record|
          claim = claims.detect { |c| c.reference == record.fetch(:claim_reference) }
          next if record.fetch(:qts_date).blank? || claim.nil?
          if claim.policy::DQTRecord.new(record).eligible? && record_matches_claim?(record, claim)
            claim.tasks.create!(task_attributes)
            @completed_tasks += 1
          end
        end
        @total_records = records.count
      end
    end

    def errors
      csv.errors
    end

    private

    def task_attributes
      {
        name: "qualifications",
        passed: true,
        manual: false,
        created_by: @admin_user
      }
    end

    def record_matches_claim?(record, claim)
      record.fetch(:date_of_birth) == claim.date_of_birth
    end
  end
end
