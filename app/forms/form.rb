class Form
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Validations::Callbacks

  attr_accessor :journey
  attr_accessor :journey_session
  attr_accessor :params

  delegate :answers, to: :journey_session

  def self.model_name
    Claim.model_name
  end

  def self.i18n_error_message(path)
    ->(object, _) { object.i18n_errors_path(path) }
  end

  # TODO RL: remove journey param and pull it from the journey_session
  def initialize(journey_session:, journey:, params:)
    super

    assign_attributes(attributes_with_current_value)
  end

  def view_path
    journey::VIEW_PATH
  end

  def i18n_namespace
    journey::I18N_NAMESPACE
  end

  def i18n_errors_path(msg, args = {})
    base_key = :"forms.#{i18n_form_namespace}.errors.#{msg}"
    I18n.t("#{i18n_namespace}.#{base_key}", default: base_key, **args)
  end

  def t(key, args = {})
    I18n.t(key, scope: "#{i18n_namespace}.forms.#{i18n_form_namespace}", **args)
  end

  def permitted_params
    @permitted_params ||= params.fetch(model_name.param_key, {}).permit(*permitted_attributes)
  end

  def persisted?
    true
  end

  private

  def permitted_attributes
    attributes.keys.map do |key|
      field = @attributes[key]

      case field.value_before_type_cast
      when []
        {key => []}
      else
        key
      end
    end
  end

  def i18n_form_namespace
    self.class.name.demodulize.gsub("Form", "").underscore
  end

  def attributes_with_current_value
    attributes.each_with_object({}) do |(attribute, _), hash|
      hash[attribute] = permitted_params[attribute]
      next unless hash[attribute].nil?

      hash[attribute] = load_current_value(attribute)
    end
  end

  def load_current_value(attribute)
    journey_session.answers.public_send(attribute) if journey_session.answers.has_attribute?(attribute)
  end
end
