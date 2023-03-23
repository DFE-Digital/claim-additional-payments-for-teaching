class AwardRangeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    max_award = options[:max]
    ActiveModel::Validations::NumericalityValidator.new({
      attributes: attributes,
      greater_than: 0,
      less_than_or_equal_to: max_award,
      message: "Enter a positive amount up to #{max_award.to_fs(:currency)} (inclusive)"
    }).validate_each(record, attribute, value)
  end
end
