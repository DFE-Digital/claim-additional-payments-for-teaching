class NationalInsuranceNumberFormatValidator < ActiveModel::EachValidator
  NINO_REGEX_FILTER = /\A[A-Z]{2}[0-9]{6}[A-D]{1}\Z/

  def validate_each(record, attribute, value)
    normalised_value = value.gsub(/\s/, "").upcase

    validate_regex(record, attribute, normalised_value)
    validate_first_character(record, attribute, normalised_value)
    validate_second_character(record, attribute, normalised_value)
    validate_prefixes(record, attribute, normalised_value)
  end

  private

  def validate_regex(record, attribute, value)
    return if record.errors[attribute].any?
    return if value.match?(NINO_REGEX_FILTER)

    record.errors.add(attribute, options[:message] || :format)
  end

  def validate_first_character(record, attribute, value)
    return if record.errors[attribute].any?

    invalid_first_charaters = %w[D F I Q U V]

    if invalid_first_charaters.include?(value[0])
      record.errors.add(attribute, options[:message] || :format)
    end
  end

  def validate_second_character(record, attribute, value)
    return if record.errors[attribute].any?

    invalid_second_charaters = %w[D F I Q U V O]

    if invalid_second_charaters.include?(value[1])
      record.errors.add(attribute, options[:message] || :format)
    end
  end

  def validate_prefixes(record, attribute, value)
    return if record.errors[attribute].any?

    invalid_prefixes = %w[BG GB KN NK NT TN ZZ]

    if invalid_prefixes.include?(value[0..1])
      record.errors.add(attribute, options[:message] || :format)
    end
  end
end
