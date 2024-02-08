module LevellingUpPremiumPayments
  extend self

  VERIFIERS = [
    AutomatedChecks::ClaimVerifiers::Identity,
    AutomatedChecks::ClaimVerifiers::Qualifications,
    AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
    AutomatedChecks::ClaimVerifiers::Employment
  ].freeze

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
    name.underscore
  end

  def notify_reply_to_id
    "03ece7eb-2a5b-461b-9c91-6630d0051aa6"
  end

  def eligibility_page_url
    "https://www.gov.uk/guidance/levelling-up-premium-payments-for-teachers"
  end

  def eligibility_criteria_url
    eligibility_page_url + "#eligibility-criteria-for-teachers"
  end

  def configuration
    PolicyConfiguration.for(self)
  end
end
