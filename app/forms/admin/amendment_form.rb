class Admin::AmendmentForm
  extend ActiveModel::Callbacks

  define_model_callbacks :validation

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  attribute :claim
  attribute :admin_user

  attribute :teacher_reference_number, :string
  attribute :national_insurance_number, :string
  attribute :date_of_birth, :date
  attribute :student_loan_plan, :string
  attribute :banking_name, :string
  attribute :bank_sort_code, :string
  attribute :bank_account_number, :string
  attribute :address_line_1, :string
  attribute :address_line_2, :string
  attribute :address_line_3, :string
  attribute :address_line_4, :string
  attribute :postcode, :string
  attribute :award_amount, :decimal
  attribute :notes, :string

  before_validation :normalise_bank_sort_code
  before_validation :nilify_student_loan_repayment_plan

  validates :teacher_reference_number,
    length: {
      is: 7,
      allow_blank: true,
      message: "Teacher reference number must be 7 digits"
    }

  validates :date_of_birth,
    presence: {
      message: "Enter a date of birth"
    }

  validates :bank_account_number,
    presence: {
      message: "Enter an account number"
    }

  validates :bank_sort_code,
    presence: {
      message: "Enter a bank sort code"
    }

  validates :notes,
    presence: {
      message: "Enter a message to explain why you are making this amendment"
    }

  validates :admin_user,
    presence: true

  validate :validate_changes_present

  def self.amendable_attributes(claim:, admin_user:)
    array = Claim::AMENDABLE_ATTRIBUTES + claim.policy::Eligibility::AMENDABLE_ATTRIBUTES + [:notes]

    if admin_user.is_service_admin?
      array << :banking_name
    end

    array
  end

  def initialize(args)
    super
  rescue ActiveRecord::MultiparameterAssignmentErrors
    self.date_of_birth = nil
  end

  def valid?
    run_callbacks :validation do
      super
    end
  end

  def student_loan_plan_options
    options = Claim::STUDENT_LOAN_PLAN_OPTIONS.map do |option|
      OpenStruct.new(id: option, name: option.humanize)
    end

    options.prepend OpenStruct.new(id: nil, name: nil)

    options
  end

  def load_data_from_claim
    self.teacher_reference_number = eligibility.teacher_reference_number
    self.national_insurance_number = claim.national_insurance_number
    self.date_of_birth = claim.date_of_birth
    self.student_loan_plan = claim.student_loan_plan

    self.banking_name = claim.banking_name
    self.bank_sort_code = claim.bank_sort_code
    self.bank_account_number = claim.bank_account_number

    self.address_line_1 = claim.address_line_1
    self.address_line_2 = claim.address_line_2
    self.address_line_3 = claim.address_line_3
    self.address_line_4 = claim.address_line_4
    self.postcode = claim.postcode

    self.award_amount = eligibility.award_amount if show_award_amount?
  end

  def show_award_amount?
    return true if claim.policy == Policies::StudentLoans

    claim.policy::Eligibility::AMENDABLE_ATTRIBUTES.include?(:award_amount)
  end

  def save
    Claim.transaction do
      amendment = claim.amendments.build(**amendment_attributes)
      amendment.claim_changes = change_hash
      amendment.save!

      eligibility.assign_attributes(eligibility_attributes)
      eligibility.save!

      claim.assign_attributes(claim_attributes)
      claim.save!

      amendment.persisted?
    end
  end

  def banking_name_disabled?
    !admin_user.is_service_admin?
  end

  def show_banking_name?
    !claim.hmrc_bank_validation_succeeded?
  end

  private

  def nilify_student_loan_repayment_plan
    if student_loan_plan == ""
      self.student_loan_plan = nil
    end
  end

  def normalise_bank_sort_code
    return if bank_sort_code.nil?

    self.bank_sort_code = bank_sort_code.gsub(/\s|-/, "")
  end

  # { "attribute1" => [before, after], "attribute2" => [before, after] }
  def change_hash
    hash = {}

    claim_attributes.each do |attr, new_value|
      old_value = claim.public_send(attr)
      hash[attr] = [old_value, new_value]
    end

    eligibility_attributes.each do |attr, new_value|
      old_value = claim.eligibility.public_send(attr)
      hash[attr] = [old_value, new_value]
    end

    hash.reject! do |attr, array|
      array[0] == array[1] || (array[0].blank? && array[1].blank?)
    end

    hash
  end

  def validate_changes_present
    if change_hash.blank?
      errors.add(:base, "To amend the claim you must change at least one value")
    end
  end

  def amendment_attributes
    hash = attributes.slice("notes")
    hash["created_by"] = admin_user
    hash
  end

  def claim_attributes
    hash = attributes.slice(*Claim::AMENDABLE_ATTRIBUTES.map(&:to_s))

    if admin_user.is_service_admin?
      hash[:banking_name] = banking_name
    end

    hash
  end

  def eligibility_attributes
    attributes.slice(*claim.policy::Eligibility::AMENDABLE_ATTRIBUTES.map(&:to_s))
  end

  def eligibility
    claim.eligibility
  end
end
