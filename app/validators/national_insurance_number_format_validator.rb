class NationalInsuranceNumberFormatValidator < ActiveModel::EachValidator
  NINO_REGEX_FILTER = /\A[A-Z]{2}[0-9]{6}[A-D]{1}\Z/

  def validate_each(record, attribute, value)
    return if value.gsub(/\s/, "").upcase.match?(NINO_REGEX_FILTER)

    record.errors.add(attribute, options[:message] || :format)
  end
end
