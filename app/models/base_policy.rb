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

  def support_email_address
    I18n.t("#{locale_key}.support_email_address")
  end

  def locale_key
    to_s.underscore
  end
end
