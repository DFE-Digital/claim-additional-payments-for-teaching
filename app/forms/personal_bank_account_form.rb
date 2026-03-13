class PersonalBankAccountForm < Form
  # Only validate against HMRC API if number of attempts is below threshold
  MAX_HMRC_API_VALIDATION_ATTEMPTS = 3
  BANKING_NAME_REGEX_FILTER = /\A[0-9A-Za-z .\/&-]*\z/

  attribute :banking_name, :string
  attribute :bank_sort_code, :string
  attribute :bank_account_number, :string

  validates :banking_name, presence: {message: i18n_error_message(:enter_banking_name)}
  validates :banking_name, format: {with: BANKING_NAME_REGEX_FILTER, message: i18n_error_message(:invalid_banking_name)}, if: -> { banking_name.present? }
  validates :bank_sort_code, presence: {message: i18n_error_message(:enter_sort_code)}
  validates :bank_account_number, presence: {message: i18n_error_message(:enter_account_number)}

  validate :bank_account_number_must_be_eight_digits
  validate :bank_sort_code_must_be_six_digits

  def save
    return false unless valid?(:save)

    journey_session.answers.assign_attributes(
      banking_name: banking_name,
      bank_sort_code: normalised_bank_detail(bank_sort_code),
      bank_account_number: normalised_bank_detail(bank_account_number)
    )

    journey_session.save!
  end

  def valid?(context = nil)
    return false unless super

    # Only perform the API call if other validations have passed
    validate_with_hmrc! if within_maximum_attempts? && context == :save

    # These errors are added from the response from HMRC
    errors.empty?
  end

  def show_warning?
    true
  end

  private

  def normalised_bank_detail(bank_detail)
    bank_detail&.gsub(/\s|-/, "")
  end

  def bank_account_number_must_be_eight_digits
    errors.add(:bank_account_number, i18n_errors_path(:format_account_number)) if bank_account_number.present? && normalised_bank_detail(bank_account_number) !~ /\A\d{8}\z/
  end

  def bank_sort_code_must_be_six_digits
    errors.add(:bank_sort_code, i18n_errors_path(:format_sort_code)) if bank_sort_code.present? && normalised_bank_detail(bank_sort_code) !~ /\A\d{6}\z/
  end

  def validate_with_hmrc!
    return unless Hmrc.configuration.enabled?

    hmrc_response = Hmrc.client.verify_personal_bank_account(
      normalised_bank_detail(bank_sort_code),
      normalised_bank_detail(bank_account_number),
      banking_name
    )

    new_hmrc_bank_validation_responses_value = journey_session.answers.hmrc_bank_validation_responses.dup << {
      code: hmrc_response.status,
      body: hmrc_response.safe_body
    }

    journey_session.answers.assign_attributes(
      hmrc_bank_validation_responses: new_hmrc_bank_validation_responses_value
    )

    # If bank details don't match according to HMRC we allow the user to try the
    # same details 3 times.
    if !hmrc_response.errored? && !hmrc_response.success?
      journey_session.answers.increment_hmrc_validation_attempt_count
    end

    if hmrc_response.errored? || !hmrc_response.success?
      journey_session.answers.assign_attributes(
        hmrc_bank_validation_succeeded: false
      )
    end

    if !hmrc_response.errored? && hmrc_response.success?
      journey_session.answers.assign_attributes(
        hmrc_bank_validation_succeeded: true
      )
    end

    journey_session.save!

    # On the 3rd unsuccessful attempt we let the user completed the form and
    # continue with the details they supplied
    if !hmrc_response.errored? && !met_maximum_attempts?
      add_error_messages_from_hmrc(hmrc_response)
    end
  end

  def add_error_messages_from_hmrc(hmrc_response)
    if !hmrc_response.sort_code_correct?
      errors.add(:bank_sort_code, i18n_errors_path(:invalid_sort_code))
    end

    if hmrc_response.sort_code_correct? && !hmrc_response.account_exists?
      errors.add(:bank_account_number, i18n_errors_path(:invalid_account_number))
    end

    if hmrc_response.sort_code_correct? && hmrc_response.account_exists? && !hmrc_response.name_match?
      errors.add(:banking_name, i18n_errors_path(:invalid_banking_name))
    end
  end

  def hmrc_validation_attempt_count
    journey_session.answers.hmrc_validation_attempt_count || 0
  end

  # TODO RL - lose one of these methods
  def within_maximum_attempts?
    hmrc_validation_attempt_count <= MAX_HMRC_API_VALIDATION_ATTEMPTS
  end

  def met_maximum_attempts?
    hmrc_validation_attempt_count >= MAX_HMRC_API_VALIDATION_ATTEMPTS
  end
end
