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

  validates :address_line_1, format: {with: ADDRESS_REGEX_FILTER, message: i18n_error_message(:address_format)}
  validates :address_line_2, format: {with: ADDRESS_REGEX_FILTER, message: i18n_error_message(:address_format)}
  validates :address_line_3, format: {with: ADDRESS_REGEX_FILTER, message: i18n_error_message(:address_format)}
  validates :address_line_4, format: {with: ADDRESS_REGEX_FILTER, message: i18n_error_message(:address_format)}

  validate :postcode_is_valid, if: -> { postcode.present? }

  def save
    return false unless valid?

    update!(attributes)
  end

  def backlink_path
    unless claim.postcode
      return Rails
          .application
          .routes
          .url_helpers
          .claim_path(params[:journey], "postcode-search")
    end

    super
  end

  private

  def postcode_is_valid
    unless UKPostcode.parse(postcode).full_valid?
      errors.add(:postcode, i18n_errors_path(:postcode_format))
    end
  end
end
