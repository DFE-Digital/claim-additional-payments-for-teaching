class SelectHomeAddressForm < Form
  attribute :address, :string
  attribute :skip_postcode_search, :boolean

  validates(
    :address,
    inclusion: {
      in: ->(form) { form.radio_options.map(&:id) },
      message: "Select an address"
    }
  )

  def radio_options
    postcode_search.addresses.map do |option|
      Option.new(
        id: option[:address],
        name: option[:address]
      )
    end
  end

  def save
    if skip_postcode_search
      journey_session.answers.update!(
        skip_postcode_search: true,
        address_line_1: nil,
        address_line_2: nil,
        address_line_3: nil,
        address_line_4: nil,
        postcode: nil
      )

      return true
    end

    return false unless valid?

    selected_address = postcode_search.addresses.detect { it[:address] == address }

    journey_session.answers.assign_attributes({
      skip_postcode_search: false,
      address_line_1: selected_address[:address_line_1]&.titleize,
      address_line_2: selected_address[:address_line_2]&.titleize,
      address_line_3: selected_address[:address_line_3]&.titleize,
      address_line_4: nil,
      postcode: selected_address[:postcode]
    })

    journey_session.save!
  end

  def completed?
    skip_postcode_search || answers.address_present?
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

  def postcode_search
    @postcode_search ||= PostcodeSearch.new(answers.postcode)
  end
end
