class SelectEmailForm < Form
  attribute :email_address_check, :boolean
  attribute :email_address
  attribute :email_verified

  validates :email_address_check, inclusion: {in: [true, false], message: ->(object, _) { object.i18n_errors_path(:select_email) }}
  validates :email_address, presence: {message: ->(object, _) { object.i18n_errors_path(:invalid_email) }}, if: -> { email_address_check == true }
  validates :email_address, format: {with: Rails.application.config.email_regexp, message: ->(object, _) { object.i18n_errors_path(:invalid_email) }},
    length: {maximum: 256, message: ->(object, _) { object.i18n_errors_path(:invalid_email) }}, if: -> { email_address.present? }

  before_validation :determine_dependant_attributes

  def save
    return false unless valid?

    update!(attributes)
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
    claim.teacher_id_user_info["email"]
  end
end
