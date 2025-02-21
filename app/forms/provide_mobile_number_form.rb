class ProvideMobileNumberForm < Form
  attribute :provide_mobile_number, :boolean

  # FIXME RL consider moving this to a subclass rather than querying the session
  validates :provide_mobile_number,
    inclusion: {
      in: [true, false],
      message: "Select yes if you would like to provide your mobile number"
    }

  def save
    return false unless valid?

    if provide_mobile_number_changed?
      journey_session.answers.assign_attributes(mobile_verified: nil)
      journey_session.answers.assign_attributes(mobile_number: nil) unless provide_mobile_number
    end

    journey_session.answers.assign_attributes(
      provide_mobile_number: provide_mobile_number
    )

    journey_session.save!
  end

  def radio_options
    [
      Option.new(id: true, name: "Yes"),
      Option.new(id: false, name: "No")
    ]
  end

  private

  def provide_mobile_number_changed?
    answers.provide_mobile_number != provide_mobile_number
  end
end
