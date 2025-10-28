class CurrentSchoolForm < Form
  MIN_LENGTH = 3

  attribute :provision_search, :string
  attribute :possible_school_id, :string

  validates :provision_search,
    presence: {message: i18n_error_message(:blank)},
    length: {minimum: MIN_LENGTH, message: i18n_error_message(:min_length)},
    if: proc { |object| object.possible_school_id.blank? || changed_query? }

  validate :validate_possible_school_exists
  validate :validate_possible_school_must_be_open

  def save
    return false if invalid? || no_results?

    if possible_school_id.present? && changed_possible_school?
      journey_session.answers.assign_attributes(
        possible_school_id:
      )
      reset_dependent_answers
    end

    if changed_query?
      journey_session.answers.assign_attributes(
        possible_school_id: nil,
        provision_search:
      )
      reset_dependent_answers
    end

    journey_session.save!
  end

  private

  def no_results?
    provision_search.present? && provision_search.size >= MIN_LENGTH && !has_results
  end

  def has_results
    @has_results ||= School.open.search(provision_search).count > 0
  end

  def possible_school
    @possible_school ||= School.find_by(id: possible_school_id)
  end

  def changed_possible_school?
    possible_school_id != journey_session.answers.current_school_id
  end

  def changed_query?
    provision_search != journey_session.answers.provision_search
  end

  def reset_dependent_answers
    journey_session.answers.assign_attributes(
      current_school_id: nil
    )
  end

  def validate_possible_school_exists
    if possible_school_id.present? && possible_school.blank?
      errors.add(:possible_school_id, "School not found")
    end
  end

  def validate_possible_school_must_be_open
    if possible_school_id.present? && possible_school&.closed?
      errors.add(:possible_school_id, "The selected school is closed")
    end
  end
end
