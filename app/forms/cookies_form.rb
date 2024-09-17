class CookiesForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :accept, :boolean

  def radio_options
    [
      OpenStruct.new(id: true, name: "Yes"),
      OpenStruct.new(id: false, name: "No")
    ]
  end
end
