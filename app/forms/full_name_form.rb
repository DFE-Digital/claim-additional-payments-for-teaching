class FullNameForm < Form
  attribute :first_name
  attribute :middle_name
  attribute :surname

  validates :first_name, presence: {message: "Enter your first name"}
  validates :first_name, length: {maximum: 100, message: "First name must be less than 100 characters"}, if: -> { first_name.present? }
  validates :first_name, name_format: {message: "First name cannot contain special characters"}

  validates :middle_name, length: {maximum: 61, message: "Middle names must be less than 61 characters"}, if: -> { middle_name.present? }
  validates :middle_name, name_format: {message: "Middle names cannot contain special characters"}

  validates :surname, presence: {message: "Enter your last name"}
  validates :surname, length: {maximum: 100, message: "Last name must be less than 100 characters"}, if: -> { surname.present? }
  validates :surname, name_format: {message: "Last name cannot contain special characters"}

  def save
    return false if invalid?

    journey_session.answers.assign_attributes(
      first_name:,
      middle_name:,
      surname:,
    )

    reset_dependent_answers_attributes
    journey_session.save!

    if journey.requires_student_loan_details?
      journey::AnswersStudentLoansDetailsUpdater.call(journey_session)
    end

    true
  end

  private

  def reset_dependent_answers_attributes
    journey_session.answers.assign_attributes(
      has_student_loan: nil,
      student_loan_plan: nil
    )
  end
end
