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

    match = EMAIL_REGEX_PATTERN.match(value)

    if match.nil?
      record.errors.add(
        attribute,
        :invalid,
        message: options.fetch(:message, "is not a valid email address"),
        value: value
      )

      return
    end

    if value.length > 320
      record.errors.add(
        attribute,
        :invalid,
        message: options.fetch(:message, "is not a valid email address"),
        value: value
      )

      return
    end

    if value.include?("..")
      record.errors.add(
        attribute,
        :invalid,
        message: options.fetch(:message, "is not a valid email address"),
        value: value
      )

      return
    end

    hostname = match[1]

    parts = hostname.split(".")

    if hostname.length > 253 || parts.size < 2
      record.errors.add(
        attribute,
        :invalid,
        message: options.fetch(:message, "is not a valid email address"),
        value: value
      )

      return
    end

    if parts.any? { |part| part.length > 63 || !HOSTNAME_PART.match?(part) }
      record.errors.add(
        attribute,
        :invalid,
        message: options.fetch(:message, "is not a valid email address"),
        value: value
      )

      return
    end

    tld = parts.last

    if !TLD_PART.match?(tld)
      record.errors.add(
        attribute,
        :invalid,
        message: options.fetch(:message, "is not a valid email address"),
        value: value
      )
    end
  end
end
