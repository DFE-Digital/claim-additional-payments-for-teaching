module EarlyCareerPayments
  class InductionData
    VALID_INDUCTION_STATUSES_2018_2019 = ["pass", "exempt"]
    VALID_INDUCTION_STATUSES_2020 = ["pass", "exempt", "in progress", "not yet completed", "induction extended"]
    private_constant :VALID_INDUCTION_STATUSES_2018_2019, :VALID_INDUCTION_STATUSES_2020

    def initialize(itt_year:, induction_status:, induction_start_date:)
      @itt_year = itt_year
      @induction_status = induction_status
      @induction_start_date = induction_start_date
    end

    def eligible?
      if itt_year_2018_or_2019?
        valid_status?
      elsif itt_year_2020?
        valid_status? && induction_start_date.present? && induction_start_date.before?(1.year.ago)
      else
        false
      end
    end

    def incomplete?
      induction_status.nil? || (itt_year_2020? && valid_status? && induction_start_date.nil?)
    end

    private

    attr_reader :itt_year, :induction_status, :induction_start_date

    def valid_status?
      return valid_induction_status?(VALID_INDUCTION_STATUSES_2018_2019) if itt_year_2018_or_2019?
      return valid_induction_status?(VALID_INDUCTION_STATUSES_2020) if itt_year_2020?

      false
    end

    def itt_year_2018_or_2019?
      itt_year == AcademicYear.new(2018) || itt_year == AcademicYear.new(2019)
    end

    def itt_year_2020?
      itt_year == AcademicYear.new(2020)
    end

    def valid_induction_status?(array)
      array.include?(induction_status&.strip&.downcase)
    end
  end
end
