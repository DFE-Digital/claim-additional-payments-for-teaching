module AutomatedChecks
  # Used to ingest a report from DQT (Database of Qualified Teachers)
  # containing qualification data such as QTS (Qualified Teacher Status)
  # award date, ITT (Initial Teacher Training) subjects and
  # post graduate degree subject.
  #
  # The records will be used to determine if a claimant's qualifications
  # make them eligible for a specific policy.
  class DQTReportConsumer
    def initialize(file, admin_user)
      @csv = DQTReportCsv.new(file)
      @admin_user = admin_user
    end

    def ingest
      @csv.rows.each do |row|
        claim = Claim.awaiting_decision.find_by(reference: row["dfeta text2"])
        next if row["dfeta qtsdate"].blank? || claim.nil?
        if claim.policy::DQTRecord.new(row.to_h).eligible? && row_matches_claim?(row, claim)
          task = claim.tasks.build(task_attributes)
          task.save!
        end
      rescue ActiveRecord::RecordInvalid
        next
      end
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
