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
            perform_qualification_check(claim, record)
            perform_identity_confirmation(claim, record)
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

    def perform_qualification_check(claim, record)
      if awaiting_task?(claim, "qualifications") && claim.policy::DqtRecord.new(record).eligible?
        claim.tasks.create!(task_attributes("qualifications"))
        @completed_tasks += 1
      end
    end

    def perform_identity_confirmation(claim, record)
      if claim.identity_verified? && awaiting_task?(claim, "identity_confirmation") && identity_matches?(claim, record)
        claim.tasks.create!(task_attributes("identity_confirmation"))
        @completed_tasks += 1
      end
    end

    def claims
      @claims ||= Claim.awaiting_decision.includes(:tasks)
    end

    def claim_for_record(record)
      claims.detect { |c| c.reference == record.fetch(:claim_reference) }
    end

    def awaiting_task?(claim, task_name)
      claim.tasks.none? { |task| task.name == task_name }
    end

    def identity_matches?(claim, record)
      record.fetch(:date_of_birth) == claim.date_of_birth && record.fetch(:surname)&.casecmp?(claim.surname)
    end

    def dqt_records
      @dqt_records ||= DqtReportCsvToRecords.new(@csv.rows).transform
    end

    def task_attributes(task_name)
      {
        name: task_name,
        passed: true,
        manual: false,
        created_by: @admin_user
      }
    end
  end
end
