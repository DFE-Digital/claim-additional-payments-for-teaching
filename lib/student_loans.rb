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

  PLANS = [
    PLAN_1 = "plan_1",
    PLAN_2 = "plan_2",
    PLAN_1_AND_2 = "plan_1_and_2",
  ].freeze

  DATES_TO_PLANS_MAP = {
    BEFORE_1_SEPT_2012 => PLAN_1,
    ON_OR_AFTER_1_SEPT_2012 => PLAN_2,
    BEFORE_AND_AFTER_1_SEPT_2012 => PLAN_1_AND_2,
  }.freeze

  # Used to determine a person's student loan plan based on their country of
  # study and the start date(s) of their course(s).
  #
  # Returns nil if the plan cannot be determined based on the information
  # provided.
  def self.determine_plan(country, course_start_date = nil)
    return PLAN_1 if PLAN_1_COUNTRIES.include?(country)

    DATES_TO_PLANS_MAP[course_start_date]
  end
end
