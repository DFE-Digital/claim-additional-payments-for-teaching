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
end
