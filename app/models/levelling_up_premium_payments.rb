module LevellingUpPremiumPayments
  extend self

  def short_name
    I18n.t("levelling_up_premium_payments.policy_short_name")
  end

  def routing_name
    PolicyConfiguration.routing_name_for_policy(self)
  end

  def policy_type
    name.underscore.dasherize
  end

  def locale_key
    routing_name.underscore
  end

  def notify_reply_to_id
    # TODO real value
    "3f85a1f7-9400-4b48-9a31-eaa643d6b977"
  end

  def eligibility_page_url
    "https://www.gov.uk/guidance/levelling-up-premium-payments-for-teachers"
  end

  def configuration
    PolicyConfiguration.for(self)
  end
end
