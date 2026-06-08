class PostcodeSearchForm < Form
  attribute :postcode, :string
  attribute :skip_postcode_search, :boolean

  validates :postcode,
    presence: {message: "Enter a postcode, for example NE1 6EE"},
    length: {maximum: 11, message: "Postcode must be 11 characters or less"}

  validates(
    :postcode,
    postcode_format: {
      message: "Enter a postcode in the correct format"
    },
    if: -> { postcode.present? }
  )

  validate(
    :postcode_has_address,
    if: -> do
      postcode.present? && UKPostcode.parse(postcode).full_valid? && !postcode_search.api_error?
    end
  )

  # Order is important hear, we must make sure to validate the postcode before
  # attempting to search for it
  def save
    if skip_postcode_search?
      # Clear address so claimant always sees enter address screen
      journey_session.answers.update!(
        skip_postcode_search: true,
        address_line_1: nil,
        address_line_2: nil,
        address_line_3: nil,
        postcode: nil
      )

      return true
    end

    return false if invalid?

    # Changing postcode clears selected address, so they always see the address
    # select screen.
    journey_session.answers.assign_attributes(
      address_line_1: nil,
      address_line_2: nil,
      address_line_3: nil,
      postcode: postcode
    )

    if postcode_search.api_error?
      journey_session.answers.assign_attributes(ordnance_survey_error: true)
    else
      journey_session.answers.assign_attributes(skip_postcode_search: false)
    end

    journey_session.save!
  end

  def completed?
    answers.skip_postcode_search? || answers.postcode.present?
  end

  def skip_postcode_search?
    skip_postcode_search
  end

  private

  def postcode_search
    @postcode_search ||= PostcodeSearch.new(postcode)
  end

  def postcode_has_address
    if postcode_search.addresses.blank?
      errors.add(:postcode, "Address not found")
    end
  end
end
