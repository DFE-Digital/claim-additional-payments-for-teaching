# frozen_string_literal: true

module BasePolicy
  def to_s
    super.demodulize
  end

  def policy_type
    locale_key.dasherize
  end

  def short_name
    I18n.t("#{locale_key}.policy_short_name")
  end

  def locale_key
    to_s.underscore
  end

  def routing_name
    PolicyConfiguration.routing_name_for_policy(self)
  end

  def configuration
    PolicyConfiguration.for(self)
  end
end
