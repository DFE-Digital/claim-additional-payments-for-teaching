class PersonalDetailsForm < Form
  NAME_REGEX_FILTER = /\A[^"=$%#&*+\/\\()@?!<>0-9]*\z/
  NINO_REGEX_FILTER = /\A[A-Z]{2}[0-9]{6}[A-D]{1}\Z/
  DOB_PARAM_CONVERSION = {
    "date_of_birth(3i)" => "day",
    "date_of_birth(2i)" => "month",
    "date_of_birth(1i)" => "year"
  }

  attribute :first_name
  attribute :middle_name
  attribute :surname
  attribute :day
  attribute :month
  attribute :year
  attribute :date_of_birth
  attribute :national_insurance_number

  validates :first_name, presence: {message: "Enter your first name"}
  validates :first_name,
    length: {maximum: 100, message: "First name must be less than 100 characters"},
    format: {with: NAME_REGEX_FILTER, message: "First name cannot contain special characters"},
    if: -> { first_name.present? }
  validates :middle_name,
    length: {maximum: 61, message: "Middle names must be less than 61 characters"},
    format: {with: NAME_REGEX_FILTER, message: "Middle names cannot contain special characters"},
    if: -> { middle_name.present? }
  validates :surname, presence: {message: "Enter your last name"}
  validates :surname,
    length: {maximum: 100, message: "Last name must be less than 100 characters"},
    format: {with: NAME_REGEX_FILTER, message: "Last name cannot contain special characters"},
    if: -> { surname.present? }
  validate :date_of_birth_criteria
  validates :national_insurance_number, presence: {message: "Enter a National Insurance number in the correct format"}
  validate :ni_number_is_correct_format

  def initialize(claim:, journey:, params:)
    super
    assign_date_attributes
  end

  def date_of_birth
    date_hash = {year:, month:, day:}
    date_args = date_hash.values.map(&:to_i)

    Date.valid_date?(*date_args) ? Date.new(*date_args) : InvalidDate.new(date_hash)
  end

  def save
    return false unless valid?

    update!({first_name:, middle_name:, surname:, date_of_birth:, national_insurance_number:})
  end

  def has_valid_name?
    valid?
    errors.exclude?(:first_name) && errors.exclude?(:surname)
  end

  def has_valid_date_of_birth?
    valid?
    errors.exclude?(:date_of_birth)
  end

  def has_valid_nino?
    valid?
    errors.exclude?(:national_insurance_number)
  end

  private

  def permitted_params
    @permitted_params ||= params.fetch(:claim, {})
      .permit(*attributes, *DOB_PARAM_CONVERSION.keys)
      .transform_keys { |key| DOB_PARAM_CONVERSION.has_key?(key) ? DOB_PARAM_CONVERSION[key] : key }
  end

  def assign_date_attributes
    self.day = permitted_params.fetch(:day, claim.date_of_birth&.day)
    self.month = permitted_params.fetch(:month, claim.date_of_birth&.month)
    self.year = permitted_params.fetch(:year, claim.date_of_birth&.year)
  end

  def ni_number_is_correct_format
    errors.add(:national_insurance_number, "Enter a National Insurance number in the correct format") if national_insurance_number.present? && !normalised_ni_number.match(NINO_REGEX_FILTER)
  end

  def normalised_ni_number
    national_insurance_number.gsub(/\s/, "").upcase
  end

  def date_of_birth_criteria
    if date_of_birth.future?
      errors.add(:date_of_birth, "Date of birth must be in the past")
    elsif number_of_date_components.between?(1, 2)
      errors.add(:date_of_birth, "Date of birth must include a day, month and year in the correct format, for example 01 01 1980")
    elsif !date_of_birth.is_a?(Date) && number_of_date_components == 3
      errors.add(:date_of_birth, "Enter a date of birth in the correct format")
    elsif number_of_date_components.zero?
      errors.add(:date_of_birth, "Enter your date of birth")
    elsif date_of_birth.year < 1000
      errors.add(:date_of_birth, "Year must include 4 numbers")
    elsif date_of_birth.year <= 1900
      errors.add(:date_of_birth, "Year must be after 1900")
    end

    errors[:date_of_birth].empty?
  end

  def number_of_date_components
    [day, month, year].compact_blank.size
  end
end
