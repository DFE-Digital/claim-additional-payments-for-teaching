module LevellingUpPremiumPayments
  # This is concerned with the award information from the spreadsheet, which will
  # contain the pre-computed amount, thereby we don't need to check the EIA or pupil premium
  # status ourselves.
  #
  # The only reason for this class to change is regarding how the monetary amount
  # is stored.
  class Award
    # The spreadsheet contains the pre-computed amount as a currency string
    # like "£2,000.00" or "No payment" and is attached to
    # https://dfedigital.atlassian.net/browse/CAPT-253
    #
    # We'll need a job to perform the initial database storage of this data.
    def initialize(school)
      raise "nil school" if school.nil?

      @school = school
    end

    def self.max
      @@maximum_award_amount_in_pounds
    end

    def has_award?
      amount_in_pounds.positive?
    end

    def amount_in_pounds
      @@urn_to_award_amount_in_pounds.fetch(@school.urn, 0)
    end

    # completely fake until information is in the public domain
    @@urn_to_award_amount_in_pounds = {
      150000 => 1_000,
      150001 => 3_000,
      160000 => 0,
      160001 => 0
    }

    @@maximum_award_amount_in_pounds = @@urn_to_award_amount_in_pounds.values.max
  end
end
