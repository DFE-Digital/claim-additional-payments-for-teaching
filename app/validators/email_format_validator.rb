# frozen_string_literal: true

# Rules and regex taken from https://github.com/alphagov/notifications-utils/blob/fd3ba3db8cfaf4ad5308aaf5efdcd4e0cf3730e8/notifications_utils/recipients.py
# which in turn was adapted from https://github.com/JoshData/python-email-validator/blob/primary/email_validator/__init__.py
# with minor tweaks for SES compatibility (we are a lot stricter with the local
# part than necessary, not allowing double quotes or semicolons to prevent SES
# Technical Failures)

# TODO: Note this have been changed to match the validation in Claim
class EmailFormatValidator
  EMAIL_REGEX = /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@([^.@][^@\s]+)$/
  PART_REGEX = /^(xn-|[a-z0-9]+)(-[a-z0-9]+)*$/i
  TLD_REGEX = /^([a-z]{2,63}|xn--([a-z0-9]+-)*[a-z0-9]+)$/

  MAX_LENGTH = 256
  MAX_HOSTNAME_LENGTH = 253
  MAX_PART_LENGTH = 63

  MIN_PARTS = 2

  def initialize(record)
    @record = record
    @email = record.email_address
  end

  def validate
    return unless email

    record.errors.add(:email_address, :invalid) unless valid?
  end

  private

  attr_reader :record, :email

  def valid?
    matches_regex? &&
      length_valid? &&
      no_consecutive_periods? &&
      hostname_valid?
  end

  def matches_regex?
    EMAIL_REGEX.match?(email)
  end

  def length_valid?
    email.length <= MAX_LENGTH
  end

  def no_consecutive_periods?
    email.exclude?("..")
  end

  def hostname_valid?
    hostname_length_valid? &&
      parts_length_valid? &&
      parts_match_regex?
  end

  def hostname_length_valid?
    hostname.length <= MAX_HOSTNAME_LENGTH
  end

  def parts_length_valid?
    parts.length >= MIN_PARTS &&
      parts.all? { |part| part.length <= MAX_PART_LENGTH }
  end

  def parts_match_regex?
    parts.all? { |part| PART_REGEX.match?(part) } &&
      TLD_REGEX.match?(parts[-1])
  end

  def hostname
    @hostname ||= EMAIL_REGEX.match(email)[1]
  end

  def parts
    @parts ||= hostname.split(".")
  end
end
