# frozen_string_literal: true

module SimplePolicyPayments
  # Checks if a school is eligible for Policy Payment. A school being
  # eligible is necessary but not sufficient for an Policy Payment award to be made.
  #
  # Whether a school is eligible for Policy Payments could be checked via a new database
  # column on `School`.
  class SchoolEligibilityCheck
    def initialize(school)
      raise "nil school" if school.nil?

      @school = school
    end

    # TODO: Determine eligibility based on the school identified - requires a school question
    def eligible? = true
  end
end
