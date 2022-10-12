module LevellingUpPremiumPayments
  # Checks if a school is eligible for LUP. A school being
  # eligible is necessary but not sufficient for an LUP award to be made.
  #
  # Whether a school is eligible for LUP could be checked via a new database
  # column on `School`.
  class SchoolEligibility
    def initialize(school)
      raise "nil school" if school.nil?

      @school = school
    end

    def eligible?
      # TODO: use first year of LUP for now but this must come from a PolicyConfiguration
      LevellingUpPremiumPayments::Award.new(school: @school, year: AcademicYear.new(2022)).has_award?
    end

    def eligible?
      LevellingUpPremiumPayments::Award.new(
        school: @school,
        year: AcademicYear.for(Date.today)
      ).has_award?
    end
  end
end
