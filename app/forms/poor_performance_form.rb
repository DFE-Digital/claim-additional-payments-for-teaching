class PoorPerformanceForm < Form
  attribute :subject_to_formal_performance_action, :boolean
  attribute :subject_to_disciplinary_action, :boolean

  validates :subject_to_formal_performance_action,
    inclusion: {
      in: [true, false],
      message: i18n_error_message("performance.inclusion")
    }

  validates :subject_to_disciplinary_action,
    inclusion: {
      in: [true, false],
      message: i18n_error_message("disciplinary.inclusion")
    }

  def radio_options
    [
      OpenStruct.new(
        id: true,
        name: "Yes"
      ),
      OpenStruct.new(
        id: false,
        name: "No"
      )
    ]
  end

  def save
    return false if invalid?

    journey_session.answers.assign_attributes(
      subject_to_formal_performance_action:,
      subject_to_disciplinary_action:
    )
    journey_session.save
  end

  def clear_answers_from_session
    journey_session.answers.assign_attributes(
      subject_to_formal_performance_action: nil,
      subject_to_disciplinary_action: nil
    )
    journey_session.save
  end
end
