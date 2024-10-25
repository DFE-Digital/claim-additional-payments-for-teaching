class PersonalDetailsForm < Form
  InvalidDate = Struct.new(:day, :month, :year, keyword_init: true) do
    def future?
      false
    end
  end

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
  validates :first_name, length: {maximum: 100, message: "First name must be less than 100 characters"}, if: -> { first_name.present? }
  validates :first_name, name_format: {message: "First name cannot contain special characters"}

  validates :middle_name, length: {maximum: 61, message: "Middle names must be less than 61 characters"}, if: -> { middle_name.present? }
  validates :middle_name, name_format: {message: "Middle names cannot contain special characters"}

  validates :surname, presence: {message: "Enter your last name"}
  validates :surname, length: {maximum: 100, message: "Last name must be less than 100 characters"}, if: -> { surname.present? }
  validates :surname, name_format: {message: "Last name cannot contain special characters"}

  validate :date_of_birth_criteria
  validates :national_insurance_number, presence: {message: "Enter a National Insurance number in the correct format"}
  validate :ni_number_is_correct_format

  def initialize(journey_session:, journey:, params:)
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

    journey_session.answers.assign_attributes(
      first_name:,
      middle_name:,
      surname:,
      date_of_birth:,
      national_insurance_number: normalised_ni_number
    )

    reset_dependent_answers_attributes

    journey_session.save!
  end

  def show_name_section?
    !(answers.logged_in_with_tid? && answers.name_same_as_tid? && has_valid_name?)
  end

  def show_date_of_birth_section?
    !(answers.logged_in_with_tid? && answers.dob_same_as_tid? && has_valid_date_of_birth?)
  end

  def show_nino_section?
    !(answers.logged_in_with_tid? && answers.nino_same_as_tid? && has_valid_nino?)
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

  def reset_dependent_answers_attributes
    journey_session.answers.assign_attributes(
      has_student_loan: nil,
      student_loan_plan: nil
    )

    if journey == Journeys::TeacherStudentLoanReimbursement
      journey_session.answers.assign_attributes(
        student_loan_repayment_amount: nil
      )
    end
  end
end
