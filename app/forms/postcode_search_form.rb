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
    if: -> { valid_postcode_entered? && !postcode_search.api_error? }
  )

  def save
    if skip_postcode_search?
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

    return false if invalid?

    journey_session.answers.assign_attributes(
      skip_postcode_search: false,
      address_line_1: nil,
      address_line_2: nil,
      address_line_3: nil,
      address_line_4: nil,
      postcode: postcode
    )

    if postcode_search.api_error?
      journey_session.answers.assign_attributes(ordnance_survey_error: true)
    else
      journey_session.answers.assign_attributes(ordnance_survey_error: false)
    end

    journey_session.save!
  end

  def completed?
    journey_session.answers.skip_postcode_search || journey_session.answers.ordnance_survey_error || valid?
  end

  def skip_postcode_search?
    skip_postcode_search
  end

  private

  def valid_postcode_entered?
    postcode.present? && UKPostcode.parse(postcode).full_valid?
  end

  def postcode_search
    @postcode_search ||= PostcodeSearch.new(postcode)
  end

  def postcode_has_address
    return if postcode_search.addresses.present?

    errors.add(:postcode, "Address not found")
  end
end
