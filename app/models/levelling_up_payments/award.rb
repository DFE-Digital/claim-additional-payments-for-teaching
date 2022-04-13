module LevellingUpPayments
  # This is concerned with the award information from the spreadsheet, which will
  # contain the pre-computed amount, thereby we don't need to check the EIA or pupil premium
  # status ourselves.
  #
  # The information from the spreadsheet could be stored in the existing `School` table,
  # or a `School` could have an optional relationship to an award amount table.
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

    def has_award?
      amount_in_pounds.positive?
    end

    def amount_in_pounds
      # this will come from the database after the amounts have been uploaded
      @school.lup_amount_in_pounds
    end
  end
end
