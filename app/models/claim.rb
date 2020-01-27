# frozen_string_literal: true

class Claim < ApplicationRecord
  TRN_LENGTH = 7
  NO_STUDENT_LOAN = "not_applicable"
  STUDENT_LOAN_PLAN_OPTIONS = StudentLoan::PLANS.dup << NO_STUDENT_LOAN
  ADDRESS_ATTRIBUTES = %w[address_line_1 address_line_2 address_line_3 address_line_4 postcode].freeze
  EDITABLE_ATTRIBUTES = [
    :first_name,
    :middle_name,
    :surname,
    :address_line_1,
    :address_line_2,
    :address_line_3,
    :address_line_4,
    :postcode,
    :date_of_birth,
    :payroll_gender,
    :teacher_reference_number,
    :national_insurance_number,
    :has_student_loan,
    :student_loan_country,
    :student_loan_courses,
    :student_loan_start_date,
    :email_address,
    :bank_sort_code,
    :bank_account_number,
    :banking_name,
    :building_society_roll_number,
  ].freeze
  FILTER_PARAMS = {
    address_line_1: true,
    address_line_2: true,
    address_line_3: true,
    address_line_4: true,
    postcode: true,
    payroll_gender: true,
    teacher_reference_number: true,
    national_insurance_number: true,
    has_student_loan: false,
    student_loan_country: false,
    student_loan_courses: false,
    student_loan_start_date: false,
    email_address: true,
    bank_sort_code: true,
    bank_account_number: true,
    created_at: false,
    date_of_birth: true,
    eligibility_id: false,
    eligibility_type: false,
    first_name: true,
    middle_name: true,
    surname: true,
    id: false,
    reference: false,
    student_loan_plan: false,
    submitted_at: false,
    updated_at: false,
    govuk_verify_fields: false,
    verify_response: true,
    banking_name: true,
    building_society_roll_number: true,
    payment_id: false,
  }.freeze
  CHECK_DEADLINE = 12.weeks
  CHECK_DEADLINE_WARNING_POINT = 2.weeks
  ATTRIBUTE_DEPENDENCIES = {
    "has_student_loan" => "student_loan_country",
    "student_loan_country" => "student_loan_courses",
    "student_loan_courses" => "student_loan_start_date",
  }.freeze

  enum student_loan_country: StudentLoan::COUNTRIES
  enum student_loan_start_date: StudentLoan::COURSE_START_DATES
  enum student_loan_courses: {one_course: 0, two_or_more_courses: 1}
  enum student_loan_plan: STUDENT_LOAN_PLAN_OPTIONS

  has_one :check

  belongs_to :eligibility, polymorphic: true, dependent: :destroy
  accepts_nested_attributes_for :eligibility, update_only: true

  belongs_to :payment, optional: true

  enum payroll_gender: {
    dont_know: 0,
    female: 1,
    male: 2,
  }

  validates :payroll_gender, on: [:gender, :submit], presence: {message: "Choose the option for the gender your school’s payroll system associates with you"}

  validates :first_name, on: [:name, :submit], presence: {message: "Enter your first name"}
  validates :first_name, length: {maximum: 100, message: "First name must be 100 characters or less"}

  validates :middle_name, length: {maximum: 100, message: "Middle name must be 100 characters or less"}

  validates :surname, on: [:name, :submit], presence: {message: "Enter your last name"}
  validates :surname, length: {maximum: 100, message: "Last name must be 100 characters or less"}

  validates :address_line_1, on: [:address, :submit], presence: {message: "Enter your building and street address"}
  validates :address_line_1, length: {maximum: 100, message: "Address lines must be 100 characters or less"}
  validates :address_line_2, length: {maximum: 100, message: "Address lines must be 100 characters or less"}
  validates :address_line_3, length: {maximum: 100, message: "Address lines must be 100 characters or less"}
  validates :address_line_4, length: {maximum: 100, message: "Address lines must be 100 characters or less"}

  validates :postcode, on: [:address, :submit], presence: {message: "Enter your postcode"}
  validates :postcode, length: {maximum: 11, message: "Postcode must be 11 characters or less"}

  validates :date_of_birth, on: [:"date-of-birth", :submit], presence: {message: "Enter your date of birth"}

  validates :teacher_reference_number, on: [:"teacher-reference-number", :submit], presence: {message: "Enter your teacher reference number"}
  validate :trn_must_be_seven_digits

  validates :national_insurance_number, on: [:"national-insurance-number", :submit], presence: {message: "Enter your National Insurance number"}
  validate :ni_number_is_correct_format

  validates :has_student_loan, on: [:"student-loan", :submit], inclusion: {in: [true, false], message: "Select yes if you have a student loan"}
  validates :student_loan_country, on: [:"student-loan-country"], presence: {message: "Select the country you lived in when you applied for your student loan"}
  validates :student_loan_courses, on: [:"student-loan-how-many-courses"], presence: {message: "Select the number of student loans you have taken out"}
  validates :student_loan_start_date, on: [:"student-loan-start-date"], presence: {message: ->(object, data) { I18n.t("validation_errors.student_loan_start_date.#{object.student_loan_courses}") }}
  validates :student_loan_plan, on: [:submit], presence: {message: "We have not been able determined your student loan repayment plan. Answer all questions about your student loan."}

  validates :email_address, on: [:"email-address", :submit], presence: {message: "Enter an email address"}
  validates :email_address, format: {with: URI::MailTo::EMAIL_REGEXP, message: "Enter an email in the format name@example.com"},
                            length: {maximum: 256, message: "Email address must be 256 characters or less"},
                            allow_blank: true

  validates :banking_name, on: [:"bank-details", :submit], presence: {message: "Enter the name on your bank account"}
  validates :bank_sort_code, on: [:"bank-details", :submit], presence: {message: "Enter a sort code"}
  validates :bank_account_number, on: [:"bank-details", :submit], presence: {message: "Enter an account number"}

  validate :bank_account_number_must_be_eight_digits
  validate :bank_sort_code_must_be_six_digits
  validate :building_society_roll_number_must_be_between_one_and_eighteen_digits
  validate :building_society_roll_number_must_be_in_a_valid_format

  validate :claim_must_not_be_ineligible, on: :submit

  before_save :normalise_trn, if: :teacher_reference_number_changed?
  before_save :normalise_ni_number, if: :national_insurance_number_changed?
  before_save :normalise_bank_account_number, if: :bank_account_number_changed?
  before_save :normalise_bank_sort_code, if: :bank_sort_code_changed?

  scope :unsubmitted, -> { where(submitted_at: nil) }
  scope :submitted, -> { where.not(submitted_at: nil) }
  scope :awaiting_checking, -> { submitted.left_outer_joins(:check).where(checks: {claim_id: nil}) }
  scope :approved, -> { joins(:check).where("checks.result" => :approved) }
  scope :rejected, -> { joins(:check).where("checks.result" => :rejected) }
  scope :approaching_check_deadline, -> { awaiting_checking.where("submitted_at < ? AND submitted_at > ?", CHECK_DEADLINE.ago + CHECK_DEADLINE_WARNING_POINT, CHECK_DEADLINE.ago) }
  scope :passed_check_deadline, -> { awaiting_checking.where("submitted_at < ?", CHECK_DEADLINE.ago) }
  scope :payrollable, -> { approved.where(payment: nil) }
  scope :by_policy, ->(policy) { where(eligibility_type: policy::Eligibility.to_s) }

  delegate :award_amount, to: :eligibility
  delegate :scheduled_payment_date, to: :payment, allow_nil: true

  def submit!
    if submittable?
      self.submitted_at = Time.zone.now
      self.reference = unique_reference
      save!
    else
      false
    end
  end

  def submitted?
    submitted_at.present?
  end

  def submittable?
    valid?(:submit) && !submitted?
  end

  def approvable?
    submitted? && !payroll_gender_missing? && !checked? && !payment_prevented_by_other_claims?
  end

  def checked?
    check&.persisted?
  end

  def payroll_gender_missing?
    %w[male female].exclude?(payroll_gender)
  end

  def payment_prevented_by_other_claims?
    ClaimsPreventingPaymentFinder.new(self).claims_preventing_payment.any?
  end

  def check_deadline_date
    (submitted_at + CHECK_DEADLINE).to_date
  end

  def address(seperator = ", ")
    Claim::ADDRESS_ATTRIBUTES.map { |attr| send(attr) }.reject(&:blank?).join(seperator)
  end

  def no_student_loan?
    !has_student_loan?
  end

  def student_loan_country_with_one_plan?
    StudentLoan::PLAN_1_COUNTRIES.include?(student_loan_country)
  end

  # Returns true if the claim has a confirmed identity. For now this can only
  # be done through GOV.UK Verify, but will change in the future.
  def identity_confirmed?
    govuk_verify_fields.any?
  end

  def name_verified?
    govuk_verify_fields.include?("first_name")
  end

  def date_of_birth_verified?
    govuk_verify_fields.include?("date_of_birth")
  end

  def payroll_gender_verified?
    govuk_verify_fields.include?("payroll_gender")
  end

  def address_from_govuk_verify?
    (ADDRESS_ATTRIBUTES & govuk_verify_fields).any?
  end

  def full_name
    [first_name, middle_name, surname].compact.join(" ")
  end

  def self.filtered_params
    FILTER_PARAMS.select { |_, v| v }.keys
  end

  def reset_dependent_answers
    ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_name|
      write_attribute(dependent_attribute_name, nil) if changed.include?(attribute_name)
    end
    self.student_loan_plan = determine_student_loan_plan
  end

  def policy
    eligibility&.class&.module_parent
  end

  def school
    eligibility&.current_school
  end

  private

  def normalise_trn
    self.teacher_reference_number = normalised_trn
  end

  def normalised_trn
    teacher_reference_number.gsub(/\D/, "")
  end

  def trn_must_be_seven_digits
    errors.add(:teacher_reference_number, "Teacher reference number must contain seven digits") if teacher_reference_number.present? && normalised_trn.length != TRN_LENGTH
  end

  def normalise_ni_number
    self.national_insurance_number = normalised_ni_number
  end

  def normalised_ni_number
    national_insurance_number.gsub(/\s/, "").upcase
  end

  def ni_number_is_correct_format
    errors.add(:national_insurance_number, "Enter a National Insurance number in the correct format") \
      if national_insurance_number.present? && !normalised_ni_number.match(/\A[A-Z]{2}[0-9]{6}[A-D]{1}\Z/)
  end

  def normalise_bank_account_number
    self.bank_account_number = normalised_bank_detail(bank_account_number)
  end

  def normalise_bank_sort_code
    self.bank_sort_code = normalised_bank_detail(bank_sort_code)
  end

  def normalised_bank_detail(bank_detail)
    bank_detail.gsub(/\s|-/, "")
  end

  def building_society_roll_number_must_be_between_one_and_eighteen_digits
    return unless building_society_roll_number.present?

    errors.add(:building_society_roll_number, "Building society roll number must be between 1 and 18 characters") \
      if building_society_roll_number.length > 18
  end

  def building_society_roll_number_must_be_in_a_valid_format
    return unless building_society_roll_number.present?

    errors.add(:building_society_roll_number, "Building society roll number must only include letters a to z, numbers, hyphens, spaces, forward slashes and full stops") \
      unless /\A[a-z0-9\-\s\.\/]{1,18}\z/i.match?(building_society_roll_number)
  end

  def bank_account_number_must_be_eight_digits
    errors.add(:bank_account_number, "Bank account number must be 8 digits  – check you've entered the correct number or check with your bank for an 8 digit version") \
      if bank_account_number.present? && normalised_bank_detail(bank_account_number) !~ /\A\d{8}\z/
  end

  def bank_sort_code_must_be_six_digits
    errors.add(:bank_sort_code, "Sort code must contain six digits") \
      if bank_sort_code.present? && normalised_bank_detail(bank_sort_code) !~ /\A\d{6}\z/
  end

  def unique_reference
    loop {
      ref = Reference.new.to_s
      break ref unless self.class.exists?(reference: ref)
    }
  end

  def claim_must_not_be_ineligible
    errors.add(:base, "You’re not eligible for this payment") if eligibility.ineligible?
  end

  def determine_student_loan_plan
    if has_student_loan?
      StudentLoan.determine_plan(student_loan_country, student_loan_start_date)
    else
      Claim::NO_STUDENT_LOAN
    end
  end
end
