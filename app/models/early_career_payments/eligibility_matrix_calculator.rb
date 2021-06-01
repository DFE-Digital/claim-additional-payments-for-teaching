module EarlyCareerPayments
  class EligibilityMatrixCalculator
    MATRIX = {
      mathematics: ["2018_2019", "2019_2020", "2020_2021"],
      physics: ["2020_2021"],
      chemistry: ["2020_2021"],
      foreign_languages: ["2020_2021"]
    }.freeze

    attr_reader :eligibility

    def initialize(eligibility)
      @eligibility = eligibility
    end

    def eligible_later?
      return false if subject == :mathematics && itt_academic_year == "2018_2019"

      MATRIX.dig(subject)&.include?(itt_academic_year) ? true : false
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
