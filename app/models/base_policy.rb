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

  def payroll_file_name
    to_s
  end

  def policies_claimable
    return [] unless const_defined?(:OTHER_CLAIMABLE_POLICIES)

    [self] + self::OTHER_CLAIMABLE_POLICIES
  end

  def policy_eligibilities_claimable
    policies_claimable.map { |p| p::Eligibility }
  end

  def eligibility_matching_attributes
    return [] unless const_defined?(:ELIGIBILITY_MATCHING_ATTRIBUTES)

    self::ELIGIBILITY_MATCHING_ATTRIBUTES
  end

  def searchable_eligibility_attributes
    return [] unless const_defined?(:SEARCHABLE_ELIGIBILITY_ATTRIBUTES)

    self::SEARCHABLE_ELIGIBILITY_ATTRIBUTES
  end

  def international_relocation_payments?
    to_s == "InternationalRelocationPayments"
  end
end
