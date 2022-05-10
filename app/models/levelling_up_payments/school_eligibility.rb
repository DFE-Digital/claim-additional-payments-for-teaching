module LevellingUpPayments
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
      LevellingUpPayments::Award.new(@school).has_award?
    end
  end
end
