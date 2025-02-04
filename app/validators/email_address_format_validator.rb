# Implementation of this validation:
# https://github.com/alphagov/notifications-utils/blob/e89dcc53c7f88ef23053d1efb2c00b8ef2ea377e/notifications_utils/recipient_validation/email_address.py#L1
# though lacking the punycode support.
class EmailAddressFormatValidator < ActiveModel::EachValidator
  VALID_LOCAL_CHARS = "a-zA-Z0-9.!#$%&'*+/=?^_`{|}~\\-"
  EMAIL_REGEX_PATTERN = /\A[#{VALID_LOCAL_CHARS}]+@([^.@][^@\s]+)\z/
  HOSTNAME_PART = /\A(xn|[a-z0-9]+)(-?-[a-z0-9]+)*\z/i
  TLD_PART = /\A([a-z]{2,63}|xn--([a-z0-9]+-)*[a-z0-9]+)\z/i

  def validate_each(record, attribute, value)
    return unless value

    unless valid_format?(value)
      add_error(record, attribute, value)
      return
    end

    unless valid_length?(value)
      add_error(record, attribute, value)
      return
    end

    if value.include?("..")
      add_error(record, attribute, value)
      return
    end

    unless valid_email_domain?(value)
      add_error(record, attribute, value)
    end
  end

  private

  def valid_format?(value)
    EMAIL_REGEX_PATTERN.match?(value)
  end

  def valid_length?(value)
    value.length <= 320
  end

  def valid_email_domain?(value)
    match = EMAIL_REGEX_PATTERN.match(value)
    return false unless match

    domain = match[1]
    domain_parts = domain.split(".")

    return false if domain.length > 253 || domain_parts.size < 2

    return false if domain_parts.any? { |part| part.length > 63 || !HOSTNAME_PART.match?(part) }

    top_level_domain = domain_parts.last
    TLD_PART.match?(top_level_domain)
  end

  def add_error(record, attribute, value)
    record.errors.add(
      attribute,
      :invalid,
      message: options.fetch(:message, "is not a valid email address"),
      value: value
    )
  end
end
