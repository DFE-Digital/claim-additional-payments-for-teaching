class Form
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attr_accessor :claim
  attr_accessor :journey
  attr_accessor :params

  delegate :persisted?, to: :claim

  def self.model_name
    Claim.model_name
  end

  def initialize(claim:, journey:, params:)
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

  def i18n_errors_path(msg)
    I18n.t("#{i18n_namespace}.forms.#{i18n_form_namespace}.errors.#{msg}")
  end

  def permitted_params
    @permitted_params ||= params.fetch(:claim, {}).permit(*permitted_attributes)
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
      journey.slug_sequence.new(claim),
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
