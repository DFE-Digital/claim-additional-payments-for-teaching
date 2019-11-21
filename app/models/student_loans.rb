# frozen_string_literal: true

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
end
