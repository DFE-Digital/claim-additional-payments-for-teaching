class Form
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :claim
  attribute :journey
  attribute :params

  def self.model_name
    Claim.model_name
  end

  def initialize(claim:, journey:, params:)
    super
  end

  def view_path
    journey::VIEW_PATH
  end

  def i18n_namespace
    journey::I18N_NAMESPACE
  end

  def backlink_path
    nil
  end
end
