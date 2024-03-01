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
      @school.levelling_up_premium_payments_awards.where(academic_year: current_academic_year.to_s).any?
    end

    private

    def current_academic_year
      JourneyConfiguration.for(LevellingUpPremiumPayments).current_academic_year
    end
  end
end
