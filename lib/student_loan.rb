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

  PLAN_1_COUNTRIES = [NORTHERN_IRELAND].freeze
  PLAN_4_COUNTRIES = [SCOTLAND].freeze

  PLANS = [
    PLAN_1 = "plan_1",
    PLAN_2 = "plan_2",
    PLAN_1_AND_2 = "plan_1_and_2",
    PLAN_4 = "plan_4",
    PLAN_3 = "plan_3",
    PLAN_1_AND_3 = "plan_1_and_3",
    PLAN_2_AND_3 = "plan_2_and_3",
    PLAN_1_AND_2_AND_3 = "plan_1_and_2_and_3",
    PLAN_4_AND_3 = "plan_4_and_3"
  ].freeze

  DATES_TO_PLANS_MAP = {
    BEFORE_1_SEPT_2012 => PLAN_1,
    ON_OR_AFTER_1_SEPT_2012 => PLAN_2,
    BEFORE_AND_AFTER_1_SEPT_2012 => PLAN_1_AND_2
  }.freeze

  # Used to determine a person's student loan plan based on their country of
  # study and the start date(s) of their course(s) if they have a student loan.
  #
  # Returns nil if the plan cannot be determined based on the information
  # provided.
  # Or returns PLAN_3 when has a postgraduate masters and/or doctoral loan
  def self.determine_plan(has_student_loan, has_postgraduate_loan, country = nil, course_start_date = nil)
    return Claim::NO_STUDENT_LOAN if !has_student_loan && !has_postgraduate_loan
    return PLAN_3 if !has_student_loan && has_postgraduate_loan

    base_plan = case country
    when SCOTLAND
      PLAN_4
    when NORTHERN_IRELAND
      PLAN_1
    else
      DATES_TO_PLANS_MAP[course_start_date]
    end

    return base_plan unless has_postgraduate_loan
    return base_plan if base_plan.nil?

    const_get([base_plan.upcase, :_AND_3].join)
  end
end
