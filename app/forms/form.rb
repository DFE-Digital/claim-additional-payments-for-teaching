class Form
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Validations::Callbacks
  include FormHelpers

  attr_accessor :journey
  attr_accessor :journey_session
  attr_accessor :params
  attr_accessor :session

  delegate :answers, to: :journey_session

  def self.model_name
    Claim.model_name
  end

  def self.i18n_error_message(path, args = {})
    ->(object, _) { object.i18n_errors_path(path, args) }
  end

  # TODO RL: remove journey param and pull it from the journey_session
  def initialize(journey_session:, journey:, params:, session: {})
    super

    assign_attributes(attributes_with_current_value)
  end

  def view_path
    journey::VIEW_PATH
  end

  def permitted_params
    @permitted_params ||= params.fetch(model_name.param_key, {}).permit(*permitted_attributes)
  end

  def persisted?
    true
  end

  # for this particular form
  # clear all associated answers from the session
  # does nothing by default
  # and should be implemented on per form basis
  # if the forms stores data to session
  def clear_answers_from_session
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
