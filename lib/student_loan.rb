# frozen_string_literal: true

module StudentLoan
  COUNTRIES = [
    ENGLAND = "england",
    NORTHERN_IRELAND = "northern_ireland",
    WALES = "wales",
    SCOTLAND = "scotland"
  ].freeze

  COURSE_START_DATES = [
    BEFORE_1_SEPT_2012 = "before_first_september_2012",
    ON_OR_AFTER_1_SEPT_2012 = "on_or_after_first_september_2012",
    BEFORE_AND_AFTER_1_SEPT_2012 = "some_before_some_after_first_september_2012"
  ].freeze

  PLANS = [
    PLAN_1 = "plan_1",
    PLAN_2 = "plan_2",
    PLAN_3 = "plan_3",
    PLAN_4 = "plan_4",
    PLAN_5 = "plan_5",
    PLAN_1_AND_2 = "plan_1_and_2",
    PLAN_1_AND_3 = "plan_1_and_3",
    PLAN_1_AND_2_AND_3 = "plan_1_and_2_and_3",
    PLAN_1_AND_4 = "plan_1_and_4",
    PLAN_2_AND_3 = "plan_2_and_3",
    PLAN_2_AND_4 = "plan_2_and_4",
    PLAN_2_AND_5 = "plan_2_and_5",
    PLAN_3_AND_4 = "plan_3_and_4",
    PLAN_3_AND_5 = "plan_3_and_5",
    PLAN_4_AND_3 = "plan_4_and_3", # NOTE: combo present on older records (replaced with plan_3_and_4)
    PLAN_4_AND_5 = "plan_4_and_5"
  ].freeze
end
