class MobileNumberFormatValidator < ActiveModel::EachValidator
  MOBILE_FORMAT_REGEX = /\A(\+44\s?)?(?:\d\s?){10,11}\z/

  def validate_each(record, attribute, value)
    return if MOBILE_FORMAT_REGEX.match?(value)

    record.errors.add(attribute, options[:message] || :format)
  end
end
