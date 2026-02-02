class Admin::FeatureFlagsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :fe_provider_dashboard, :boolean

  # {
  #   name: "feature_flag_name",
  #   description: "some text",
  #   hint: "optional hint text"
  # }
  def flags
    [
      OpenStruct.new(
        name: "fe_provider_dashboard",
        description: "Provider dashboard journey"
      )
    ].select do |struct|
      FeatureFlag.exists?(name: struct.name)
    end
  end

  def options
    [
      OpenStruct.new(id: true, name: "Enabled"),
      OpenStruct.new(id: false, name: "Disabled")
    ]
  end

  def load_data
    attribute_names.each do |attr_name|
      public_send "#{attr_name}=", FeatureFlag.enabled?(attr_name)
    end
  end
end
