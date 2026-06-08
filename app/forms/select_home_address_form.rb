class SelectHomeAddressForm < Form
  attribute :skip_postcode_search, :boolean

  attribute :address, :string

  validates(
    :address,
    inclusion: {
      in: ->(form) { form.radio_options.map(&:id) },
      message: "Select an address"
    }
  )

  validate :selected_address_present

  def radio_options
    postcode_search.addresses.map do |option|
      Option.new(
        id: option[:address],
        name: option[:address]
      )
    end
  end

  def save
    if skip_postcode_search?
      # Claimant has picked "I can’t find my address in the list". They may have
      # done this after previously selecting an address and navigating back, so
      # we need to clear any address we have stored.
      journey_session.answers.assign_attributes(
        skip_postcode_search: true,
        address_line_1: nil,
        address_line_2: nil,
        address_line_3: nil,
        postcode: nil
      )

      return true
    end

    return false if invalid?

    journey_session.answers.update!({
      address_line_1: selected_address[:address_line_1].titleize,
      address_line_2: selected_address[:address_line_2].titleize,
      address_line_3: selected_address[:address_line_3].titleize
    })
  end

  def completed?
    answers.skip_postcode_search? || answers.address_present?
  end

  def skip_postcode_search?
    skip_postcode_search
  end

  private

  # We're assuming that PostcodeSearch will be reading from the cache at this
  # point, as we wouldn't have reached this form if there was an API error...
  def postcode_search
    @postcode_search ||= PostcodeSearch.new(answers.postcode)
  end

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

  def selected_address_present
    return if selected_address.present?

    errors.add(:address, "Address could not be saved")

    # This shouldn't be able to happen as we _should_ be reading from the cache
    Sentry.capture_message(
      "Selected address not found in postcode search results",
      extra: {
        selected_address: address,
        postcode_search_results: postcode_search.addresses,
        journey_session_id: journey_session.id
      }
    )
  end

  def selected_address
    @selected_address = postcode_search.addresses.detect do |option|
      option[:address] == address
    end
  end
end
