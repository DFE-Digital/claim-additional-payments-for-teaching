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
    attr_reader :qts_award_date

    # The record transformed from a DQTReportCsv. Expected to contain the keys:
    # :qts_date - The date the teacher achieved qualified teacher status.
    #             Format: %d/%m/%Y
    def initialize(record)
      @qts_award_date = record.fetch(:qts_date)
    end

    def eligible?
      eligible_qts_date?
    end

    private

    def eligible_qts_date?
      qts_award_date.present? && AcademicYear.for(qts_award_date) >= StudentLoans.first_eligible_qts_award_year
    end
  end
end
