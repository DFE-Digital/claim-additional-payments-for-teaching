class BankDetailsForm < Form
  # Only validate against HMRC API if number of attempts is below threshold
  MAX_HMRC_API_VALIDATION_ATTEMPTS = 3
  BANKING_NAME_REGEX_FILTER = /\A[0-9A-Za-z .\/&-]*\z/

  attribute :banking_name, :string
  attribute :bank_sort_code, :string
  attribute :bank_account_number, :string

  attr_reader :hmrc_api_validation_attempted, :hmrc_api_validation_succeeded, :hmrc_api_response_error

  validates :banking_name, presence: {message: i18n_error_message(:enter_banking_name)}
  validates :banking_name, format: {with: BANKING_NAME_REGEX_FILTER, message: i18n_error_message(:invalid_banking_name)}, if: -> { banking_name.present? }
  validates :bank_sort_code, presence: {message: i18n_error_message(:enter_sort_code)}
  validates :bank_account_number, presence: {message: i18n_error_message(:enter_account_number)}

  validate :bank_account_number_must_be_eight_digits
  validate :bank_sort_code_must_be_six_digits

  # This should be the last validation specified to prevent unnecessary API calls
  validate :bank_account_is_valid

  def save
    return false unless valid?

    journey_session.answers.assign_attributes(
      banking_name: banking_name,
      bank_sort_code: normalised_bank_detail(bank_sort_code),
      bank_account_number: normalised_bank_detail(bank_account_number),
      hmrc_bank_validation_succeeded: hmrc_bank_validation_succeeded
    )

    journey_session.save!
  end

  def hmrc_bank_validation_succeeded
    hmrc_api_validation_succeeded?
  end

  def hmrc_api_validation_attempted?
    @hmrc_api_validation_attempted == true && @hmrc_api_response_error != true
  end

  def hmrc_api_validation_succeeded?
    @hmrc_api_validation_succeeded == true && @hmrc_api_response_error != true
  end

  private

  def hmrc_validation_attempt_count
    journey_session.answers.hmrc_validation_attempt_count
  end

  def normalised_bank_detail(bank_detail)
    bank_detail&.gsub(/\s|-/, "")
  end

  def bank_account_number_must_be_eight_digits
    errors.add(:bank_account_number, i18n_errors_path(:format_account_number)) if bank_account_number.present? && normalised_bank_detail(bank_account_number) !~ /\A\d{8}\z/
  end

  def bank_sort_code_must_be_six_digits
    errors.add(:bank_sort_code, i18n_errors_path(:format_sort_code)) if bank_sort_code.present? && normalised_bank_detail(bank_sort_code) !~ /\A\d{6}\z/
  end

  def bank_account_is_valid
    return if @bank_account_is_valid_processed
    return unless can_validate_with_hmrc_api?

    response = nil

    begin
      response = Hmrc.client.verify_personal_bank_account(normalised_bank_detail(bank_sort_code), normalised_bank_detail(bank_account_number), banking_name)

      @hmrc_api_validation_attempted = true
      @hmrc_api_validation_succeeded = true if response.success?

      if !response.success?
        journey_session.answers.increment_hmrc_validation_attempt_count
      end

      unless met_maximum_attempts?
        errors.add(:bank_sort_code, i18n_errors_path(:invalid_sort_code)) unless response.sort_code_correct?
        errors.add(:bank_account_number, i18n_errors_path(:invalid_account_number)) if response.sort_code_correct? && !response.account_exists?
        errors.add(:banking_name, i18n_errors_path(:invalid_banking_name)) if response.sort_code_correct? && response.account_exists? && !response.name_match?
      end
    rescue Hmrc::ResponseError => e
      journey_session.answers.increment_hmrc_validation_attempt_count
      response = e.response
      @hmrc_api_response_error = true
    ensure
      new_hmrc_bank_validation_responses_value = journey_session.answers.hmrc_bank_validation_responses.dup << {code: response.code, body: response.body}
      journey_session.answers.assign_attributes(
        hmrc_bank_validation_responses: new_hmrc_bank_validation_responses_value
      )

      journey_session.save!

      @bank_account_is_valid_processed = true
    end
  end

  def can_validate_with_hmrc_api?
    errors.empty? && Hmrc.configuration.enabled? && within_maximum_attempts?
  end

  def within_maximum_attempts?
    hmrc_validation_attempt_count <= MAX_HMRC_API_VALIDATION_ATTEMPTS
  end

  def met_maximum_attempts?
    hmrc_validation_attempt_count >= MAX_HMRC_API_VALIDATION_ATTEMPTS
  end
end
