module EarlyCareerPayments
  class EligibilityMatrixCalculator
    attr_reader :eligibility

    def initialize(eligibility)
      @eligibility = eligibility
    end

    def eligible_later?
      return false if subject == :mathematics && itt_academic_year == "2018_2019"

      MATRIX.dig(subject.to_s, itt_academic_year).nil? ? false : true
    end

    private

    def subject
      eligibility.eligible_itt_subject&.to_sym
    end

    def itt_academic_year
      eligibility.itt_academic_year
    end
  end
end
