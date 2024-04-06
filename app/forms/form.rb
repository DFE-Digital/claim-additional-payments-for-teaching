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
  end

  def update!(attrs)
    ActiveRecord::Base.transaction do
      claim.attributes = attrs
      reset_eligibility_dependent_answers(attrs)
      claim.save!
    end
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
    @permitted_params ||= params.fetch(:claim, {}).permit(*attributes)
  end

  private

  # TODO: this probably shouldn't belong in the eligibility but more in the journey
  # leaving it here for now
  def reset_eligibility_dependent_answers(attrs)
    return if params[:slug] == "qualification-details"

    claim.reset_eligibility_dependent_answers(reset_attrs(attrs))
  end

  def reset_attrs(attrs)
    return [] unless attrs["eligibility_attributes"]

    attrs["eligibility_attributes"].keys
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
end
