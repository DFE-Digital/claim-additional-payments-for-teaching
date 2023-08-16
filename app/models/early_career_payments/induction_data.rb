module EarlyCareerPayments
  class InductionData
    PASS_INDUCTION_STATUSES = ["pass", "exempt"]
    IN_PROGRESS_INDUCTION_STATUSES = ["in progress", "not yet completed", "induction extended"]
    private_constant :PASS_INDUCTION_STATUSES, :IN_PROGRESS_INDUCTION_STATUSES

    def initialize(itt_year:, induction_status:, induction_start_date:)
      @itt_year = itt_year
      @induction_status = induction_status
      @induction_start_date = induction_start_date
    end

    def eligible?
      case AcademicYear.new(itt_year)
      when AcademicYear.new(2018), AcademicYear.new(2019)
        valid_induction_status?(PASS_INDUCTION_STATUSES)
      when AcademicYear.new(2020)
        valid_induction_status?(PASS_INDUCTION_STATUSES + IN_PROGRESS_INDUCTION_STATUSES) &&
          induction_start_date.before?(1.year.ago)
      else
        false
      end
    end

    private

    attr_reader :itt_year, :induction_status, :induction_start_date

    def valid_induction_status?(array)
      array.include?(induction_status&.strip&.downcase)
    end
  end
end
