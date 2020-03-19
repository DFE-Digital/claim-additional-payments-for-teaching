module AutomatedChecks
  # Used to ingest a report from DQT (Database of Qualified Teachers)
  # containing qualification data such as QTS (Qualified Teacher Status)
  # award date, ITT (Initial Teacher Training) subjects and
  # post graduate degree subject.
  #
  # The records will be used to determine if a claimant's qualifications
  # make them eligible for a specific policy.
  class DQTReportConsumer
    attr_reader :csv

    def initialize(file, admin_user)
      @csv = DQTReportCsv.new(file)
      @admin_user = admin_user
    end

    def ingest
      return if errors.any?

      claims = Claim.awaiting_task("qualifications")
      csv.rows.each do |row|
        reference = row.fetch("dfeta text2")
        qts_date = row.fetch("dfeta qtsdate")
        claim = claims.detect { |c| c.reference == reference }
        next if qts_date.blank? || claim.nil?
        if claim.policy::DQTRecord.new(row.to_h).eligible? && row_matches_claim?(row, claim)
          claim.tasks.create!(task_attributes)
        end
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

    def row_matches_claim?(row, claim)
      Date.parse(row["birthdate"]) == claim.date_of_birth
    end
  end
end
