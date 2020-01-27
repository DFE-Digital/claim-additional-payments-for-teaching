module MathsAndPhysics
  extend self

  def start_page_url
    "/maths-and-physics/start" # Temporary start page during private beta
  end

  def eligibility_page_url
    "https://www.gov.uk/government/publications/additional-payments-for-teaching-eligibility-and-payment-details/claim-a-payment-for-teaching-maths-or-physics-eligibility-and-payment-details"
  end

  def routing_name
    "maths-and-physics"
  end

  def notify_reply_to_id
    "29493350-ceec-4142-bd29-34ee363d5f62"
  end

  def feedback_url
    "https://docs.google.com/forms/d/e/1FAIpQLSfwPUxmNHqSnQ6RJ-0nedu5F2FRibBF5UIJ_EciTPcWQg581A/viewform"
  end

  def short_name
    I18n.t("maths_and_physics.policy_short_name")
  end
end
