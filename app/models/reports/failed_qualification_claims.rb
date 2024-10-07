require "csv"
require "excel_utils"

module Reports
  class FailedQualificationClaims
    NAME = "Claims with failed qualification status"
    HEADERS = [
      "Claim reference",
      "Teacher reference number",
      "Policy name",
      "Decision date",
      "Decision agent",
      "Answered qualification",
      "Answered ITT start year",
      "Answered ITT subject",
      "DQT ITT subjects",
      "DQT ITT start year",
      "DQT QTS award date",
      "DQT qualification name"
    ].freeze

    def initialize
      @claims = Claim.includes(:tasks).where(tasks: {name: "qualifications", passed: false}).approved
    end

    def to_csv
      CSV.generate(write_headers: true, headers: HEADERS) do |csv|
        @claims.each do |claim|
          csv << row(
            claim.reference,
            claim.eligibility.teacher_reference_number,
            claim.policy,
            claim.latest_decision.created_at,
            claim.latest_decision.created_by.full_name,
            claim.eligibility.qualification,
            claim.eligibility.itt_academic_year.start_year,
            claim.eligibility.eligible_itt_subject,
            dqt_itt_subjects(claim),
            dqt_itt_start_date(claim),
            dqt_qts_date(claim),
            dqt_qts_qualification_name(claim)
          )
        end
      end
    end

    private

    def row(*entries)
      entries.map { |entry| ExcelUtils.escape_formulas(entry) }
    end

    def dqt_itt_subjects(claim)
      unless claim.dqt_teacher_status.empty?
        claim.dqt_teacher_status["initial_teacher_training"].fetch_values("subject1", "subject2", "subject3").compact.join(",")
      end
    end

    def dqt_itt_start_date(claim)
      unless claim.dqt_teacher_status.empty?
        claim.dqt_teacher_status["initial_teacher_training"]["programme_start_date"]
      end
    end

    def dqt_qts_date(claim)
      unless claim.dqt_teacher_status.empty?
        claim.dqt_teacher_status["qualified_teacher_status"]["qts_date"]
      end
    end

    def dqt_qts_qualification_name(claim)
      unless claim.dqt_teacher_status.empty?
        claim.dqt_teacher_status["qualified_teacher_status"]["name"]
      end
    end
  end
end
