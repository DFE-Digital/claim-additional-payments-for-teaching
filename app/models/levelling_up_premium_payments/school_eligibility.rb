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
      LevellingUpPremiumPayments::Award.new(school: @school, year: current_academic_year).has_award?
    end

    private

    def current_academic_year
      PolicyConfiguration.for(LevellingUpPremiumPayments).current_academic_year
    end
  end
end
