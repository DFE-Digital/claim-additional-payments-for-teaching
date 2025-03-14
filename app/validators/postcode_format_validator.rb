class PostcodeFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if UKPostcode.parse(value).full_valid?

    record.errors.add(attribute, options[:message] || :format)
  end
end
