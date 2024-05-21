class SelectHomeAddressForm < Form
  attribute :address, :string
  attribute :address_line_1, :string
  attribute :postcode, :string

  validates :address, presence: true

  def address_data
    return [] if postcode.blank?

    @address_data ||= Rails.cache.fetch("address_data/#{postcode}", expires_in: 1.hour) do
      OrdnanceSurvey::Client.new.api.search_places.index(
        params: {postcode:}
      )
    end
  end

  def backlink_path
    Rails
      .application
      .routes
      .url_helpers
      .claim_path(params[:journey], "postcode-search")
  end

  def save
    return false unless valid?

    address_parts = address.split(":")
    update!({
      address_line_1: address_parts[1].titleize,
      address_line_2: address_parts[2].titleize,
      address_line_3: address_parts[3].titleize,
      postcode: address_parts[4]
    })
  end
end
