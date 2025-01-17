class SelectHomeAddressForm < Form
  attribute :address, :string
  attribute :address_line_1, :string
  attribute :postcode, :string

  validates :address, presence: true, unless: -> { skip_postcode_search? }
  validate :address_selected, if: -> { skip_postcode_search? }

  def address_data
    return [] if postcode.blank?

    @address_data ||= Rails.cache.fetch("address_data/#{postcode}", expires_in: 1.hour) do
      OrdnanceSurvey::Client.new.api.search_places.index(
        params: {postcode:}
      )
    end
  end

  def save
    return false unless valid?

    address_parts = address.split(":")

    journey_session.answers.assign_attributes({
      address_line_1: address_parts[1].titleize,
      address_line_2: address_parts[2].titleize,
      address_line_3: address_parts[3].titleize,
      postcode: address_parts[4]
    })

    journey_session.save!
  end

  def completed?
    skip_postcode_search? || valid?
  end

  private

  def skip_postcode_search?
    journey_session.answers.skip_postcode_search
  end

  def address_selected
    errors.add(:address) if journey_session.answers.address_line_1.blank?
  end
end
