class Form
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Validations::Callbacks

  attr_accessor :claim
  attr_accessor :journey
  attr_accessor :journey_session
  attr_accessor :params

  def self.model_name
    Claim.model_name
  end

  def self.i18n_error_message(path)
    ->(object, _) { object.i18n_errors_path(path) }
  end

  # TODO RL: remove journey param and pull it from the journey_session
  def initialize(claim:, journey_session:, journey:, params:)
    super

    assign_attributes(attributes_with_current_value)
  end

  def update!(attrs)
    claim.update!(attrs)
  end

  def view_path
    journey::VIEW_PATH
  end

  def i18n_namespace
    journey::I18N_NAMESPACE
  end

  def backlink_path
    return unless page_sequence.previous_slug
    Rails
      .application
      .routes
      .url_helpers
      .claim_path(params[:journey], page_sequence.previous_slug)
  end

  def i18n_errors_path(msg, args = {})
    base_key = :"forms.#{i18n_form_namespace}.errors.#{msg}"
    I18n.t("#{i18n_namespace}.#{base_key}", default: base_key, **args)
  end

  def permitted_params
    @permitted_params ||= params.fetch(model_name.param_key, {}).permit(*permitted_attributes)
  end

  def persisted?
    true
  end

  private

  def permitted_attributes
    attribute_names
  end

  def i18n_form_namespace
    self.class.name.demodulize.gsub("Form", "").underscore
  end

  def page_sequence
    @page_sequence ||= Journeys::PageSequence.new(
      claim,
      journey.slug_sequence.new(claim, journey_session),
      nil,
      params[:slug]
    )
  end

  def attributes_with_current_value
    attributes.each_with_object({}) do |(attribute, _), attributes|
      attributes[attribute] = permitted_params[attribute]
      next unless attributes[attribute].nil?

      attributes[attribute] = load_current_value(attribute)
    end
  end

  def load_current_value(attribute)
    return journey_session.answers[attribute] if journey_session.answers.key?(attribute)

    # TODO: re-implement when the underlying claim and eligibility data sources
    # are moved to an alternative place e.g. a session hash

    # Some, but not all attributes are present directly on the claim record.
    return claim.public_send(attribute) if claim.has_attribute?(attribute)

    # At the moment, some attributes are unique to a policy eligibility record,
    # so we need to loop through all the claims in the wrapper and check each
    # eligibility individually; if the search fails, it should return `nil`.
    claim.claims.each do |c|
      return c.eligibility.public_send(attribute) if c.eligibility.has_attribute?(attribute)
    end
    nil
  end
end
