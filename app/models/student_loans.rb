# frozen_string_literal: true

module StudentLoans
  def self.start_page_url
    if Rails.env.production?
      "https://www.gov.uk/guidance/teachers-claim-back-your-student-loan-repayments"
    else
      "/#{routing_name}/claim"
    end
  end

  def self.routing_name
    "student-loans"
  end

  def self.notify_reply_to_id
    "962b3044-cdd4-4dbe-b6ea-c461530b3dc6"
  end
end
