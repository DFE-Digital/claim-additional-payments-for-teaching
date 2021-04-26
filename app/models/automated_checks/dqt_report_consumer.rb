module AutomatedChecks
  # Used to ingest a report from DQT (Database of Qualified Teachers) that
  # contain qualification and identity information for claimants and
  # automatically perform tasks based on the data in the report.
  #
  # Any undecided claims that match records in the report are checked against
  # the report data and both an identity confirmation check and a qualification
  # check is performed:
  #
  #   - if the identity information in the claim matches the data in the report,
  #     the claim is marked as having its identity confirmed
  #   - if the qualifications in the report make the claimant eligible for the
  #     policy they are claiming against, the claim is marked as having had its
  #     qualifications checked
  #
  class DqtReportConsumer
    attr_reader :csv, :completed_tasks

    def initialize(file, admin_user)
      @csv = DqtReportCsv.new(file)
      @admin_user = admin_user
      @completed_tasks = 0
    end

    def ingest
      ActiveRecord::Base.transaction do
        dqt_records.each do |record|
          claim = claim_for_record(record)

          if claim
            @completed_tasks += UpdateAdminClaimTasksWithDqt.new(
              claim: claim,
              admin_user: @admin_user,
              dqt_teacher_status: record
            ).perform
          end
        end
      end
    end

    def errors
      csv.errors
    end

    def total_claims_checked
      claims.size
    end

    private

    def claims
      @claims ||= Claim.awaiting_decision.includes(:tasks)
    end

    def claim_for_record(record)
      claims.detect { |c| c.reference == record.fetch(:claim_reference) }
    end

    def dqt_records
      @dqt_records ||= DqtReportCsvToRecords.new(@csv.rows).transform
    end
  end
end
