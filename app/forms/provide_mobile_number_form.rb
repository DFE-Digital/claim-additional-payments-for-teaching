class ProvideMobileNumberForm < Form
  attribute :provide_mobile_number, :boolean

  # FIXME RL consider moving this to a subclass rather than querying the session
  validates :provide_mobile_number,
    inclusion: {
      in: [true, false],
      message: "Select yes if you would like to provide your mobile number"
    },
    if: -> { answers.class.module_parent == Journeys::AdditionalPaymentsForTeaching }

  def save
    return false unless valid?

    if provide_mobile_number_changed?
      journey_session.answers.assign_attributes(mobile_verified: nil)
    end

    journey_session.answers.assign_attributes(
      provide_mobile_number: provide_mobile_number
    )

    journey_session.save!
  end

  def radio_options
    [
      OpenStruct.new(id: true, name: "Yes"),
      OpenStruct.new(id: false, name: "No")
    ]
  end

  private

  def provide_mobile_number_changed?
    answers.provide_mobile_number != provide_mobile_number
  end
end
