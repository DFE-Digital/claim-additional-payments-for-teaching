module LevellingUpPremiumPayments
  extend self

  def short_name
    I18n.t("levelling_up_premium_payments.policy_short_name")
  end

  def routing_name
    Journey.routing_name_for_policy(self)
  end
end
