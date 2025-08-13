class DateOfBirthForm < Form
  include ActiveModel::Dirty

  InvalidDate = Struct.new(:day, :month, :year, keyword_init: true) do
    def future?
      false
    end
  end

  DOB_PARAM_CONVERSION = {
    "date_of_birth(3i)" => "day",
    "date_of_birth(2i)" => "month",
    "date_of_birth(1i)" => "year"
  }

  attribute :day
  attribute :month
  attribute :year
  attribute :date_of_birth

  validate :date_of_birth_criteria

  def initialize(journey_session:, journey:, params:, session: {})
    super
    assign_date_attributes
  end

  def date_of_birth
    date_hash = {year:, month:, day:}
    date_args = date_hash.values.map(&:to_i)

    Date.valid_date?(*date_args) ? Date.new(*date_args) : InvalidDate.new(date_hash)
  end

  def save
    return false if invalid?

    journey_session.answers.assign_attributes(
      date_of_birth:
    )
    journey_session.save!

    true
  end

  private

  def permitted_params
    @permitted_params ||= params.fetch(:claim, {})
      .permit(*attributes, *DOB_PARAM_CONVERSION.keys)
      .transform_keys { |key| DOB_PARAM_CONVERSION.has_key?(key) ? DOB_PARAM_CONVERSION[key] : key }
  end

  def assign_date_attributes
    self.day = permitted_params.fetch(:day, answers.date_of_birth&.day)
    self.month = permitted_params.fetch(:month, answers.date_of_birth&.month)
    self.year = permitted_params.fetch(:year, answers.date_of_birth&.year)
  end

  def date_of_birth_criteria
    if date_of_birth.future?
      errors.add(:date_of_birth, "Date of birth must be in the past")
    elsif number_of_date_components.between?(1, 2)
      errors.add(:date_of_birth, "Date of birth must include a day, month and year in the correct format, for example 01 01 1980")
    elsif number_of_date_components.zero?
      errors.add(:date_of_birth, "Enter your date of birth")
    elsif date_of_birth.is_a?(InvalidDate)
      errors.add(:date_of_birth, "Enter a date of birth in the correct format")
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
