class SelectHomeAddressForm < Form
  attribute :address, :string
  attribute :address_line_1, :string
  attribute :postcode, :string
  attribute :skip_postcode_search, :boolean

  validate :validate_address_selected, unless: -> { skip_postcode_search? }
  validate :validate_address_entered, if: -> { skip_postcode_search? }

  def radio_options
    address_data.map do |option|
      id = [
        option[:address],
        option[:address_line_1],
        option[:address_line_2],
        option[:address_line_3],
        option[:postcode]
      ].join(":")

      Option.new(
        id:,
        name: option[:address]
      )
    end
  end

  def save
    return false unless valid?

    if skip_postcode_search?
      journey_session.answers.assign_attributes(
        skip_postcode_search:
      )
    else
      address_parts = address.split(":")

      journey_session.answers.assign_attributes({
        address_line_1: address_parts[1].titleize,
        address_line_2: address_parts[2].titleize,
        address_line_3: address_parts[3].titleize,
        postcode: address_parts[4]
      })
    end

    journey_session.save!
  end

  def completed?
    skip_postcode_search? || valid?
  end

  private

  def address_data
    return [] if postcode.blank?

    @address_data ||= Rails.cache.fetch("address_data/#{postcode}", expires_in: 1.hour) do
      OrdnanceSurvey::Client.new.api.search_places.index(
        params: {postcode:}
      )
    end
  end

  def skip_postcode_search?
    journey_session.answers.skip_postcode_search || skip_postcode_search
  end

  def validate_address_selected
    if journey_session.answers.address_line_1.present? && journey_session.answers.postcode.present?
      return
    end

    if address.present?
      return
    end

    errors.add(:address, "Select an address")
  end

  def validate_address_entered
    if journey_session.answers.address_line_1.blank? && journey_session.answers.postcode.blank?
      errors.add(:address, "Enter an address") if journey_session.answers.address_line_1.blank?
    end
  end
end
