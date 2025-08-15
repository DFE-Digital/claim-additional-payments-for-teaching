class NationalInsuranceNumberForm < Form
  NINO_REGEX_FILTER = /\A[A-Z]{2}[0-9]{6}[A-D]{1}\Z/

  attribute :national_insurance_number

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
      national_insurance_number: normalised_ni_number
    )
    journey_session.save!

    true
  end

  private

  def normalised_ni_number
    national_insurance_number.gsub(/\s/, "").upcase
  end
end
