# frozen_string_literal: true

module StudentLoans
  COUNTRIES = [
    ENGLAND = "england",
    NORTHERN_IRELAND = "northern_ireland",
    WALES = "wales",
    SCOTLAND = "scotland",
  ].freeze

  COURSE_START_DATES = [
    BEFORE_1_SEPT_2012 = "before_first_september_2012",
    ON_OR_AFTER_1_SEPT_2012 = "on_or_after_first_september_2012",
    BEFORE_AND_AFTER_1_SEPT_2012 = "some_before_some_after_first_september_2012",
  ].freeze

  PLAN_1_COUNTRIES = [NORTHERN_IRELAND, SCOTLAND].freeze
end
