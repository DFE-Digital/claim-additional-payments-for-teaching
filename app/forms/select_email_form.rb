class SelectEmailForm < Form
  attribute :email_address_check, :boolean
  attribute :email_address
  attribute :email_verified

  validates :email_address_check, inclusion: {in: [true, false], message: i18n_error_message(:select_email)}
  validates :email_address, presence: {message: i18n_error_message(:invalid_email)}, if: -> { email_address_check == true }
  validates :email_address, format: {with: Rails.application.config.email_regexp, message: i18n_error_message(:invalid_email)},
    length: {maximum: Rails.application.config.email_max_length, message: i18n_error_message(:invalid_email)}, if: -> { email_address.present? }

  before_validation :determine_dependant_attributes

  def save
    return false unless valid?

    journey_session.answers.assign_attributes(
      email_address: email_address,
      email_verified: email_verified,
      email_address_check: email_address_check
    )
    journey_session.save!
  end

  def determine_dependant_attributes
    if email_address_check == true
      self.email_address = email_address_from_teacher_id
      self.email_verified = true
    else
      self.email_address = nil
      self.email_verified = nil
    end
  end

  def email_address_from_teacher_id
    answers.teacher_id_user_info["email"]
  end
end
