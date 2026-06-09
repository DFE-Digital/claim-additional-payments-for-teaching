class SelectHomeAddressForm < Form
  attribute :address, :string
  attribute :skip_postcode_search, :boolean

  validates(
    :address,
    inclusion: {
      in: ->(form) { form.radio_options.map(&:id) },
      message: "Select an address"
    },
    unless: :skip_postcode_search
  )

  def radio_options
    address_data.map do |option|
      Option.new(
        id: option[:address],
        name: option[:address]
      )
    end
  end

  def save
    return false unless valid?

    if skip_postcode_search?
      journey_session.answers.assign_attributes(
        skip_postcode_search: true,
        address_line_1: nil,
        address_line_2: nil,
        address_line_3: nil,
        address_line_4: nil,
        postcode:
      )
    else
      selected_address = address_data.detect { it[:address] == address }

      journey_session.answers.assign_attributes({
        skip_postcode_search: false,
        address_line_1: selected_address[:address_line_1].titleize,
        address_line_2: selected_address[:address_line_2].titleize,
        address_line_3: selected_address[:address_line_3].titleize,
        address_line_4: nil,
        postcode: selected_address[:postcode]
      })
    end

    journey_session.save!
  end

  def completed?
    skip_postcode_search? || answers.address_present? || valid?
  end

  private

  def load_current_value(attribute)
    if attribute.to_s == "address"
      [
        answers.address_line_1,
        answers.address_line_2,
        answers.address_line_3,
        answers.address_line_4,
        answers.postcode
      ].compact.join(", ")
    else
      super
    end
  end

  def address_data
    return [] if answers.postcode.blank?

    @address_data ||= Rails.cache.fetch("address_data/#{answers.postcode}", expires_in: 1.hour) do
      OrdnanceSurvey::Client.new.api.search_places.index(
        params: {postcode: answers.postcode}
      )
    end
  end

  def skip_postcode_search?
    journey_session.answers.skip_postcode_search || skip_postcode_search
  end
end
