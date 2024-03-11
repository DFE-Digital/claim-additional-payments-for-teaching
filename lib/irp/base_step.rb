class BaseStep
  include ActiveModel::Model
  include ActionView::Helpers::TranslationHelper
  include Rails.application.routes.url_helpers

  attr_reader :form,
              :path,
              :fields,
              :question_type,
              :question,
              :question_hint,
              :valid_answers

  delegate :errors, to: :form

  class << self
    include Rails.application.routes.url_helpers

    def path
      irp_step_path(name: self::ROUTE_KEY)
    end
  end

  def initialize(form)
    @form = form
    @path = irp_step_path(name: self.class::ROUTE_KEY)
    @fields = self.class::REQUIRED_FIELDS
    @fields = self.class::REQUIRED_FIELDS + self.class::OPTIONAL_FIELDS if self.class.const_defined?(:OPTIONAL_FIELDS)

    setup_fields_accessors
    initialize_fields
    configure_step
    setup_multi_question_type_labels
    setup_fields_validation
    Rails.logger.debug { "  Rendering page using #{self.class.name}" }
  end

  def configure_step
    raise("Define Me")
  end

  def update(**kwargs)
    kwargs.each { |field, value| public_send("#{field}=".to_sym, value) }
  end

  def url_options
    { only_path: true }
  end

  def template
    "step/base_step"
  end

  def radio_field?
    question_type == :radio
  end

  def date_field?
    question_type == :date
  end

  def select_field?
    question_type == :select
  end

  def multi_field?
    question_type == :multi
  end

  def answer
    return @answer if @answer.present?

    form_value = form&.public_send(fields.first)
    selected_answer = Array(valid_answers).detect { _1.value.to_s == form_value || _1.value == form_value }
    value = selected_answer&.label
    value = form_value if form_value.is_a?(Date)

    @answer = Answer.new(
      value: value,
      label: selected_answer&.label,
      field_name: fields.first,
    )
  end

  def answers
    fields.map do |field|
      value = public_send(field)
      key = self.class::ROUTE_KEY.sub("-", "_")
      Answer.new(
        value: value,
        label: t("steps.#{key}.#{field}.text"),
        field_name: field,
      )
    end
  end

  private

  def setup_fields_accessors
    fields.each { self.class.attr_accessor(_1) }
  end

  def initialize_fields
    fields.each { public_send("#{_1}=".to_sym, form&.public_send(_1)) }
  end

  def setup_fields_validation
    setup_required_fields_validation
    setup_radio_question_validation if radio_field? || select_field?
  end

  def setup_required_fields_validation
    self.class::REQUIRED_FIELDS.each do |field|
      self.class.validates(field, presence: true)
    end
  end

  def setup_radio_question_validation
    field = self.class::REQUIRED_FIELDS.first
    self.class.validates_inclusion_of(field, in: self.class::VALID_ANSWERS_OPTIONS)
  end

  def setup_multi_question_type_labels
    return unless multi_field?

    key = self.class::ROUTE_KEY.sub("-", "_")

    fields.each do |field|
      label = "#{field}_label".to_sym
      instance_variable_set("@#{label}", t("steps.#{key}.#{field}.text"))
      self.class.attr_reader(label)
    end
  end
end
