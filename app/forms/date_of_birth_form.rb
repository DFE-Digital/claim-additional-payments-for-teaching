class DateOfBirthForm < Form
  include DateOfBirth

  self.date_of_birth_field = :date_of_birth

  def save
    return false if invalid?

    journey_session.answers.update!(
      date_of_birth:
    )
  end
end
