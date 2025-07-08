# Wraps inclusion validator but allows passing a callable as `allow_nil` option.
class IncludedValidator < ActiveModel::EachValidator
  def validate(record)
    attributes.each do |attribute|
      value = record.read_attribute_for_validation(attribute)
      next if value.nil? && allow_nil?(record)
      validate_each(record, attribute, value)
    end
  end

  def validate_each(record, attribute, value)
    ActiveModel::Validations::InclusionValidator
      .new(options.except(:allow_nil).merge(attributes: [attribute]))
      .validate_each(record, attribute, value)
  end

  private

  def allow_nil?(record)
    if options[:allow_nil].respond_to?(:to_proc)
      options[:allow_nil].to_proc.call(record)
    else
      options[:allow_nil]
    end
  end
end
