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

  validate :postcode_has_address, if: -> { postcode.present? }

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
      postcode:
    )

    journey_session.save!
  end

  def completed?
    journey_session.answers.skip_postcode_search || journey_session.answers.ordnance_survey_error || valid?
  end

  def skip_postcode_search?
    skip_postcode_search
  end

  private

  def address_data
    return nil if postcode.blank?

    @address_data ||= Rails.cache.fetch("address_data/#{postcode}", expires_in: 1.hour) do
      OrdnanceSurvey::Client.new.api.search_places.index(
        params: {postcode:}
      )
    end
  end

  def postcode_has_address
    return nil unless UKPostcode.parse(postcode).full_valid?
    return unless address_data.nil?

    journey_session.answers.assign_attributes(ordnance_survey_error: false)
    errors.add(:postcode, "Address not found")
  rescue OrdnanceSurvey::Client::ResponseError => e
    Sentry.capture_exception(e)

    errors.add(:postcode, "Postcode search is currently unavailable. Please try again or enter your address manually.")
    journey_session.answers.assign_attributes(ordnance_survey_error: true)
    journey_session.save!
  end
end
