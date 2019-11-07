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
end
