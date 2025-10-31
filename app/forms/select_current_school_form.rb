class SelectCurrentSchoolForm < Form
  attribute :possible_school_id, :string # school GUID

  validates :possible_school_id, presence: {message: i18n_error_message(:blank)}

  def radio_options
    results
  end

  def save
    return unless valid?

    journey_session.answers.assign_attributes(
      current_school_id: possible_school_id
    )
    journey_session.save!
  end

  def completed?
    journey_session.answers.current_school_id.present?
  end

  private

  def current_school
    @current_school ||= School.find(possible_school_id)
  end

  def results
    @results ||= if journey_session.answers.possible_school_id.present?
      School.open.where(id: possible_school_id)
    else
      School.open.search(provision_search)
    end
  end

  def provision_search
    journey_session.answers.provision_search
  end
end
