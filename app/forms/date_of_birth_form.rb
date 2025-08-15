class DateOfBirthForm < Form
  include DateOfBirth
  self.date_of_birth_field = :date_of_birth

  def save
    return false if invalid?

    journey_session.answers.assign_attributes(
      date_of_birth:
    )
    journey_session.save!

    true
  end
end
