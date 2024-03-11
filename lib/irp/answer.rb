class Answer
  include ActionView::Helpers::TranslationHelper

  def initialize(value:, label:, hint: nil, field_name: nil)
    @value = value
    @label = label
    @hint = hint
    @field_name = field_name
    @formatted_value = format(value)
  end

  attr_reader :value, :label, :hint, :field_name, :formatted_value

  private

  def format(value)
    return value.strftime("%d-%m-%Y") if value.is_a?(Date)
    return t("steps.#{value}") if [TrueClass, FalseClass].include?(value.class)

    value
  end
end
