class PersonalDetailsForm < Form
  include ActiveModel::Dirty
  include DateOfBirth
  self.date_of_birth_field = :date_of_birth

  NINO_REGEX_FILTER = /\A[A-Z]{2}[0-9]{6}[A-D]{1}\Z/

  attribute :first_name
  attribute :middle_name
  attribute :surname
  attribute :national_insurance_number

  validates :first_name, presence: {message: "Enter your first name"}
  validates :first_name, length: {maximum: 100, message: "First name must be less than 100 characters"}, if: -> { first_name.present? }
  validates :first_name, name_format: {message: "First name cannot contain special characters"}

  validates :middle_name, length: {maximum: 61, message: "Middle names must be less than 61 characters"}, if: -> { middle_name.present? }
  validates :middle_name, name_format: {message: "Middle names cannot contain special characters"}

  validates :surname, presence: {message: "Enter your last name"}
  validates :surname, length: {maximum: 100, message: "Last name must be less than 100 characters"}, if: -> { surname.present? }
  validates :surname, name_format: {message: "Last name cannot contain special characters"}

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
      first_name:,
      middle_name:,
      surname:,
      date_of_birth:,
      national_insurance_number: normalised_ni_number
    )

    reset_dependent_answers_attributes
    journey_session.save!

    if journey.requires_student_loan_details?
      journey::AnswersStudentLoansDetailsUpdater.call(journey_session)
    end

    true
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

  def normalised_ni_number
    national_insurance_number.gsub(/\s/, "").upcase
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
        award_amount: nil
      )

      if national_insurance_number_changed?
        journey_session.answers.assign_attributes(
          student_loan_amount_seen: false
        )
      end
    end
  end
end
