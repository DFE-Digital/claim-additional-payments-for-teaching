class NameFormatValidator < ActiveModel::EachValidator
  NAME_REGEX_FILTER = /\A[^\[\]\^"=$%#&*+\/\\()@?!<>_`|{}~0-9]*\z/

  def validate_each(record, attribute, value)
    return unless value.present?

    unless NAME_REGEX_FILTER.match?(value)
      record.errors.add(attribute, options[:message])
    end
  end
end
