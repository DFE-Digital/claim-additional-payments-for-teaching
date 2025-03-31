class AddressForm < Form
  attribute :address_line_1
  attribute :address_line_2
  attribute :address_line_3
  attribute :address_line_4
  attribute :postcode

  # The idea is to filter things that in a CSV export might be malicious in MS Excel
  # A whitelist would be inappropiate as these fields could contain valid special letters e.g. accents and umlauts
  ADDRESS_REGEX_FILTER = /\A[^'"=$%#*+\/\\()@?!<>]*\z/
  ADDRESS_MAX_CHARS = 100
  POSTCODE_MAX_CHARS = 11

  ADDRESS_LINE_1_VALIDATION = /\A(?=.*[a-zA-Z0-9])[\w\s,.'-]+\z/
  ADDRESS_LINE_2_VALIDATION = /\A(?=.*[a-zA-Z])[\w\s,.'-]+\z/
  ADDRESS_LINE_3_VALIDATION = /\A[a-zA-Z\s,.'-]+\z/

  validates :address_line_1, presence: {message: i18n_error_message(:address_line_1_blank)}
  validates :address_line_2, presence: {message: i18n_error_message(:address_line_2_blank)}
  validates :address_line_3, presence: {message: i18n_error_message(:address_line_3_blank)}
  # NOTE: address_line_4 is optional
  validates :postcode, presence: {message: i18n_error_message(:postcode_blank)}

  validates :address_line_1, length: {maximum: ADDRESS_MAX_CHARS, message: i18n_error_message(:address_line_max_chars)}
  validates :address_line_2, length: {maximum: ADDRESS_MAX_CHARS, message: i18n_error_message(:address_line_max_chars)}
  validates :address_line_3, length: {maximum: ADDRESS_MAX_CHARS, message: i18n_error_message(:address_line_max_chars)}
  validates :address_line_4, length: {maximum: ADDRESS_MAX_CHARS, message: i18n_error_message(:address_line_max_chars)}
  validates :postcode, length: {maximum: POSTCODE_MAX_CHARS, message: i18n_error_message(:postcode_max_chars)}

  validate :validate_address_line_1, if: -> { address_line_1.present? }
  validate :validate_address_line_2, if: -> { address_line_2.present? }
  validate :validate_address_line_3, if: -> { address_line_3.present? }
  validates :address_line_4, format: {with: ADDRESS_REGEX_FILTER, message: i18n_error_message(:address_format)}

  validates(
    :postcode,
    postcode_format: {
      message: i18n_error_message(:postcode_format)
    },
    if: -> { postcode.present? }
  )

  def save
    return false unless valid?

    journey_session.answers.assign_attributes(
      address_line_1: address_line_1,
      address_line_2: address_line_2,
      address_line_3: address_line_3,
      address_line_4: address_line_4,
      postcode: postcode
    )

    journey_session.save!
  end

  private

  def validate_address_line_1
    unless ADDRESS_REGEX_FILTER.match(address_line_1) && ADDRESS_LINE_1_VALIDATION.match(address_line_1)
      errors.add(:address_line_1, i18n_errors_path(:address_format))
    end
  end

  def validate_address_line_2
    unless ADDRESS_REGEX_FILTER.match(address_line_2) && ADDRESS_LINE_2_VALIDATION.match(address_line_2)
      errors.add(:address_line_2, i18n_errors_path(:address_format))
    end
  end

  def validate_address_line_3
    unless ADDRESS_REGEX_FILTER.match(address_line_3) && ADDRESS_LINE_3_VALIDATION.match(address_line_3)
      errors.add(:address_line_3, i18n_errors_path(:address_format))
    end
  end
end
