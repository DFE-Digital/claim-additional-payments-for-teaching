module StudentLoans
  # Used to model a record in DQT for the Student Loans
  # reimbursement policy.
  #
  # Should be initialised with data from a row in the report
  # requested from the Database of Qualified Teachers.
  #
  # Determines the eligibility of a teacher's qualifications for
  # the Student Loans reimbursement.
  #
  #   qts_award_date: The date the teacher achieved qualified
  #                   teacher status.
  class DqtRecord
    delegate(
      :qts_award_date,
      :itt_subject_codes,
      :itt_start_date,
      :degree_codes,
      :qualification_name,
      to: :record
    )

    # The record transformed from a DQTReportCsv. Expected to contain the keys:
    # :qts_date - The date the teacher achieved qualified teacher status.
    #             Format: %d/%m/%Y
    def initialize(record, _ = nil)
      @record = record
    end

    def eligible?
      eligible_qts_award_date?
    end

    def eligible_qts_award_date?
      qts_award_date.present? && AcademicYear.for(qts_award_date) >= StudentLoans.first_eligible_qts_award_year
    end

    def eligible_qualification_subject?
      [itt_subject_codes, degree_codes].none?(&:empty?)
    end

    private

    attr_reader :record
  end
end
