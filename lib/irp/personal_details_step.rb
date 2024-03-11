class PersonalDetailsStep < BaseStep
  ROUTE_KEY = "personal-details".freeze

  REQUIRED_FIELDS = %i[
    email_address
    family_name
    given_name
    phone_number
    date_of_birth
    address_line_1
    city
    postcode
    sex
    nationality
    passport_number
    student_loan
  ].freeze

  OPTIONAL_FIELDS = %i[
    middle_name
    address_line_2
  ].freeze

  SEX_OPTIONS = %w[female male].freeze

  validates :phone_number, phone: { possible: true, types: %i[voip mobile] }
  validates :nationality, inclusion: { in: NATIONALITIES }
  validates :sex, inclusion: { in: SEX_OPTIONS }
  validates :postcode, postcode: true
  validates :passport_number, length: { maximum: 20 }
  validate :valid_passport_number
  validate :age_less_than_maximum
  validate :minimum_age

  validate do |record|
    EmailFormatValidator.new(record).validate
    FutureDateValidator.new(record, :date_of_birth).validate
  end

  def configure_step
    @question = t("steps.personal_details.question")
    @question_type = :multi
    @student_loan_valid_answers = [
      Answer.new(value: true, label: t("steps.contract_details.answers.yes.text")),
      Answer.new(value: false, label: t("steps.contract_details.answers.no.text")),
    ]
  end

  attr_reader :student_loan_valid_answers

  def template
    "step/personal_details"
  end

private

  def age_less_than_maximum
    return unless date_of_birth.present? && (Date.current.year - date_of_birth.year) >= MAX_AGE

    errors.add(:date_of_birth, :over_max_age)
  end

  def valid_passport_number
    return if passport_number.blank?

    # Reject if it contains any characters other than alphanumeric
    unless /\A[a-zA-Z0-9]+\z/.match?(passport_number)
      errors.add(:passport_number, :invalid)
      return
    end

    # Reject if it doesn't contain at least one number
    unless /\d/.match?(passport_number)
      errors.add(:passport_number, :invalid)
    end
  end

  def minimum_age
    # rubocop:disable Rails/Blank
    return unless date_of_birth.present?
    # rubocop:enable Rails/Blank

    errors.add(:date_of_birth, :below_min_age) unless date_of_birth <= MIN_AGE.years.ago.to_date
  end

  MAX_AGE = 80
  MIN_AGE = 21
  private_constant :MAX_AGE, :MIN_AGE
end
