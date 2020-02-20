# frozen_string_literal: true

# Module namespace specific to the policy for claiming back your student loan
# payments.
#
# This payment is available to teachers that qualified after 2013 teaching
# specific subjects in state-funded secondary schools in eligible local
# authorities. Full details of the eligibility criteria can be found at the URL
# defined by `StudentLoans.eligibility_page_url`.
module StudentLoans
  extend self

  def start_page_url
    if Rails.env.production?
      "https://www.gov.uk/guidance/teachers-claim-back-your-student-loan-repayments"
    else
      "/#{routing_name}/claim"
    end
  end

  def eligibility_page_url
    "https://www.gov.uk/government/publications/additional-payments-for-teaching-eligibility-and-payment-details/teachers-claim-back-your-student-loan-repayments-eligibility-and-payment-details"
  end

  def routing_name
    "student-loans"
  end

  def notify_reply_to_id
    "962b3044-cdd4-4dbe-b6ea-c461530b3dc6"
  end

  def feedback_url
    "https://docs.google.com/forms/d/e/1FAIpQLSdAyOxHme39E8lMnD2qY029mmk4Lpn84soYg2vLrT5BV9IUSg/viewform?usp=sf_link"
  end

  def short_name
    I18n.t("student_loans.policy_short_name")
  end

  # Returns the AcademicYear during or after which teachers must have completed
  # their Initial Teacher Training and been awarded QTS to be eligible to make
  # a claim. Anyone qualifying before this academic year should not be able to
  # make a claim.
  #
  # Teachers that qualified after 2013 are eligible to claim back student loans
  # repayments for 10 years. Their first claim will be made in the subsequent
  # year because they are retrospectively claiming *back* repayments made during
  # the *financial year*. So for example if you qualify in 2021/2022, you are
  # eligible to claim back student loan repayments you make in the 2021/2022
  # "financial year", which ends April 2022, and the claim for that period can
  # be made from the start of the 2022/2023 "academic year".
  #
  # So to give concrete examples, teachers qualifying in 2013/2014 can make
  # claims up to 2024/2025, and a teacher qualifying in 2014/2015 can make
  # claims up to 2025/2026 and so on.
  def first_eligible_qts_award_year
    [
      AcademicYear.new(2013),
      (configuration.current_academic_year - 11),
    ].max
  end

  def configuration
    PolicyConfiguration.for(self)
  end
end
