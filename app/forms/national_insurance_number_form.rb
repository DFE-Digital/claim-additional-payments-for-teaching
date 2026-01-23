class NationalInsuranceNumberForm < Form
  NINO_REGEX_FILTER = /\A[A-Z]{2}[0-9]{6}[A-D]{1}\Z/

  before_validation do
    if national_insurance_number.present?
      self.national_insurance_number = national_insurance_number.gsub(/\s/, "").upcase
    end
  end

  attribute :national_insurance_number, :string, strip_all_whitespace: true

  validates :national_insurance_number, presence: {message: "Enter a National Insurance number in the correct format"}
  validates(
    :national_insurance_number,
    national_insurance_number_format: {
      message: "Enter a National Insurance number in the correct format"
    },
    if: -> { national_insurance_number.present? }
  )

  def save
    return false if invalid?

    journey_session.answers.assign_attributes(
      national_insurance_number: national_insurance_number
    )
    journey_session.save!

    true
  end
end
