class BankDetailsForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :claim
  attribute :banking_name, :string
  attribute :bank_sort_code, :string
  attribute :bank_account_number, :string
  attribute :building_society_roll_number, :string

  validates :banking_name, presence: {message: "Enter a name on the account"}
  validates :bank_sort_code, presence: {message: "Enter a sort code"}
  validates :bank_account_number, presence: {message: "Enter an account number"}
  validates :building_society_roll_number, presence: {message: "Enter a roll number"}, if: -> { claim.building_society? }

  validate :bank_account_number_must_be_eight_digits
  validate :bank_sort_code_must_be_six_digits
  validate :building_society_roll_number_must_be_between_one_and_eighteen_digits
  validate :building_society_roll_number_must_be_in_a_valid_format
  validate :bank_account_is_valid

  private

  def normalised_bank_detail(bank_detail)
    bank_detail.gsub(/\s|-/, "")
  end

  def bank_account_number_must_be_eight_digits
    errors.add(:bank_account_number, "Account number must be 8 digits") \
      if bank_account_number.present? && normalised_bank_detail(bank_account_number) !~ /\A\d{8}\z/
  end

  def bank_sort_code_must_be_six_digits
    errors.add(:bank_sort_code, "Sort code must be 6 digits") \
      if bank_sort_code.present? && normalised_bank_detail(bank_sort_code) !~ /\A\d{6}\z/
  end

  def building_society_roll_number_must_be_between_one_and_eighteen_digits
    return unless building_society_roll_number.present?

    errors.add(:building_society_roll_number, "Building society roll number must be between 1 and 18 characters") \
      if building_society_roll_number.length > 18
  end

  def building_society_roll_number_must_be_in_a_valid_format
    return unless building_society_roll_number.present?

    errors.add(:building_society_roll_number, "Building society roll number must only include letters a to z, numbers, hyphens, spaces, forward slashes and full stops") \
      unless /\A[a-z0-9\-\s.\/]{1,18}\z/i.match?(building_society_roll_number)
  end

  def bank_account_is_valid
    return unless Hmrc.configuration.enabled? && banking_name.present? && bank_sort_code.present? && bank_account_number.present?

    begin
      response = Hmrc.client.verify_personal_bank_account(bank_sort_code, bank_account_number, banking_name)

      errors.add(:bank_sort_code, "Enter a valid sort code") unless response.sort_code_correct?
      errors.add(:bank_account_number, "Enter the account number associated with the name on the account and/or sort code") if response.sort_code_correct? && !response.account_exists?
      errors.add(:banking_name, "Enter a valid name on the account") if response.sort_code_correct? && response.account_exists? && !response.name_match?
    rescue Hmrc::ResponseError
    end
  end
end
