# frozen_string_literal: true

class Claim < ApplicationRecord
  include ::OneTimePasswordCheckable

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
    :has_masters_doctoral_loan,
    :postgraduate_masters_loan,
    :postgraduate_doctoral_loan,
    :email_address,
    :provide_mobile_number,
    :mobile_number,
    :bank_or_building_society,
    :bank_sort_code,
    :bank_account_number,
    :banking_name,
    :building_society_roll_number,
    :one_time_password
  ].freeze
  AMENDABLE_ATTRIBUTES = %i[
    teacher_reference_number
    national_insurance_number
    date_of_birth
    student_loan_plan
    bank_sort_code
    bank_account_number
    building_society_roll_number
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
    has_masters_doctoral_loan: false,
    postgraduate_masters_loan: false,
    postgraduate_doctoral_loan: false,
    email_address: true,
    provide_mobile_number: false,
    mobile_number: true,
    bank_sort_code: true,
    bank_account_number: true,
    created_at: false,
    date_of_birth: true,
    date_of_birth_day: true,
    date_of_birth_month: true,
    date_of_birth_year: true,
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
    bank_or_building_society: false,
    banking_name: true,
    building_society_roll_number: true,
    payment_id: false,
    academic_year: false,
    personal_data_removed_at: false,
    email_verified: false,
    one_time_password: true,
    sent_one_time_password_at: false,
    mobile_verified: false,
    one_time_password_category: false,
    assigned_to_id: true,
    policy_options_provided: false
  }.freeze
  DECISION_DEADLINE = 14.weeks
  DECISION_DEADLINE_WARNING_POINT = 2.weeks
  ATTRIBUTE_DEPENDENCIES = {
    "has_student_loan" => ["student_loan_country", "has_masters_doctoral_loan", "postgraduate_masters_loan", "postgraduate_doctoral_loan"],
    "student_loan_country" => ["student_loan_courses"],
    "student_loan_courses" => ["student_loan_start_date"],
    "bank_or_building_society" => ["banking_name", "bank_account_number", "bank_sort_code", "building_society_roll_number"],
    "provide_mobile_number" => ["mobile_number"],
    "mobile_number" => ["mobile_verified"],
    "email_address" => ["email_verified"]
  }.freeze

  # Use AcademicYear as custom ActiveRecord attribute type
  attribute :academic_year, AcademicYear::Type.new

  attribute :date_of_birth_day, :integer
  attribute :date_of_birth_month, :integer
  attribute :date_of_birth_year, :integer

  enum student_loan_country: StudentLoan::COUNTRIES
  enum student_loan_start_date: StudentLoan::COURSE_START_DATES
  enum student_loan_courses: {one_course: 0, two_or_more_courses: 1}
  enum student_loan_plan: STUDENT_LOAN_PLAN_OPTIONS
  enum bank_or_building_society: {personal_bank_account: 0, building_society: 1}

  has_many :decisions, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :amendments, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_one :support_ticket, dependent: :destroy

  belongs_to :eligibility, polymorphic: true, inverse_of: :claim, dependent: :destroy
  accepts_nested_attributes_for :eligibility, update_only: true

  belongs_to :payment, optional: true
  belongs_to :assigned_to, class_name: "DfeSignIn::User",
    inverse_of: :assigned_claims,
    optional: true

  enum payroll_gender: {
    dont_know: 0,
    female: 1,
    male: 2
  }

  validates :academic_year_before_type_cast, format: {with: PolicyConfiguration::ACADEMIC_YEAR_REGEXP}

  validates :payroll_gender, on: [:gender, :submit], presence: {message: "Select the gender recorded on your school’s payroll system or select whether you do not know"}

  validates :first_name, on: [:"personal-details", :submit], presence: {message: "Enter your first name"}
  validates :first_name,
    on: [:"personal-details", :submit],
    length: {
      in: 2..30,
      message: "First name must be between 2 and 30 characters"
    },
    if: -> { first_name.present? }

  validates :middle_name,
    on: [:"personal-details", :submit],
    length: {
      maximum: 61,
      message: "Middle names must be less than 61 characters"
    },
    if: -> { middle_name.present? }

  validates :surname, on: [:"personal-details", :submit], presence: {message: "Enter your last name"}
  validates :surname,
    on: [:"personal-details", :submit],
    length: {
      in: 2..30,
      message: "Last name must be between 2 and 30 characters"
    },
    if: -> { surname.present? }

  validates :address_line_1, on: [:address], presence: {message: "Enter a house number or name"}, if: :has_ecp_or_lupp_policy?
  validates :address_line_1, on: [:address, :submit], presence: {message: "Enter a building and street address"}, unless: :has_ecp_or_lupp_policy?
  validates :address_line_1, length: {maximum: 100, message: "Address lines must be 100 characters or less"}
  validates :address_line_2, length: {maximum: 100, message: "Address lines must be 100 characters or less"}
  validates :address_line_2, on: [:address], presence: {message: "Enter a building and street address"}, if: :has_ecp_or_lupp_policy?
  validates :address_line_3, length: {maximum: 100, message: "Address lines must be 100 characters or less"}
  validates :address_line_3, on: [:address], presence: {message: "Enter a town or city"}
  validates :address_line_4, length: {maximum: 100, message: "Address lines must be 100 characters or less"}
  validates :address_line_4, on: [:address], presence: {message: "Enter a county"}

  validates :postcode, on: [:address, :submit], presence: {message: "Enter a real postcode"}
  validates :postcode, length: {maximum: 11, message: "Postcode must be 11 characters or less"}
  validate :postcode_is_valid, if: -> { postcode.present? }

  validate :date_of_birth_criteria, on: [:"personal-details", :submit, :amendment]

  validates :teacher_reference_number, on: [:"teacher-reference-number", :submit, :amendment], presence: {message: "Enter your teacher reference number"}
  validate :trn_must_be_seven_digits

  validates :national_insurance_number, on: [:"personal-details", :submit, :amendment], presence: {message: "Enter a National Insurance number in the correct format"}
  validate :ni_number_is_correct_format

  validates :has_student_loan, on: [:"student-loan", :submit], inclusion: {in: [true, false], message: "Select yes if you are currently repaying a student loan"}
  validates :student_loan_country, on: [:"student-loan-country"], presence: {message: "Select where your home address was when you applied for your student loan"}
  validates :student_loan_courses, on: [:"student-loan-how-many-courses"], presence: {message: "Select how many higher education courses you took out a student loan for"}
  validates :student_loan_start_date, on: [:"student-loan-start-date"], presence: {message: ->(object, data) { I18n.t("validation_errors.student_loan_start_date.#{object.student_loan_courses}") }}
  validates :student_loan_plan, on: [:submit, :amendment], presence: {message: "We have not been able determined your student loan repayment plan. Answer all questions about your student loan."}

  validates :has_masters_doctoral_loan, on: [:"masters-doctoral-loan", :submit], inclusion: {in: [true, false], message: "Select yes if you have a postgraduate masters and/or doctoral loan"}, if: :no_student_loan?
  validates :postgraduate_masters_loan, on: [:"masters-loan", :submit], inclusion: {in: [true, false], message: "Select yes if you are currently repaying a Postgraduate Master’s Loan"}, unless: -> { no_masters_doctoral_loan? }
  validates :postgraduate_doctoral_loan, on: [:"doctoral-loan", :submit], inclusion: {in: [true, false], message: "Select yes if you are currently repaying a Postgraduate Doctoral Loan"}, unless: -> { no_masters_doctoral_loan? }

  validates :email_address, on: [:"email-address", :submit], presence: {message: "Enter an email address"}
  validates :email_address, format: {with: Rails.application.config.email_regexp, message: "Enter an email address in the correct format, like name@example.com"},
    length: {maximum: 256, message: "Email address must be 256 characters or less"}, if: -> { email_address.present? }

  validates :provide_mobile_number, on: [:"provide-mobile-number", :submit], inclusion: {in: [true, false], message: "Select yes if you would like to provide your mobile number"}, if: :has_ecp_or_lupp_policy?
  validates :mobile_number, on: [:"mobile-number", :submit], presence: {message: "Enter a mobile number, like 07700 900 982 or +44 7700 900 982"}, if: -> { provide_mobile_number == true && has_ecp_or_lupp_policy? }
  validates :mobile_number,
    format: {
      with: /\A(\+44\s?)?(?:\d\s?){10,11}\z/,
      message: "Enter a valid mobile number, like 07700 900 982 or +44 7700 900 982"
    }, if: -> { provide_mobile_number == true && mobile_number.present? && has_ecp_or_lupp_policy? }

  validates :bank_or_building_society, on: [:"bank-or-building-society", :submit], presence: {message: "Select if you want the money paid in to a personal bank account or building society"}
  validates :banking_name, on: [:"personal-bank-account", :"building-society-account", :submit, :amendment], presence: {message: "Enter a name on the account"}
  validates :bank_sort_code, on: [:"personal-bank-account", :"building-society-account", :submit, :amendment], presence: {message: "Enter a sort code"}
  validates :bank_account_number, on: [:"personal-bank-account", :"building-society-account", :submit, :amendment], presence: {message: "Enter an account number"}
  validates :building_society_roll_number, on: [:"building-society-account", :submit, :amendment], presence: {message: "Enter a roll number"}, if: -> { building_society? }

  validates :payroll_gender, on: [:"payroll-gender-task", :submit], presence: {message: "You must select a gender that will be passed to HMRC"}

  validate :bank_account_number_must_be_eight_digits
  validate :bank_sort_code_must_be_six_digits
  validate :building_society_roll_number_must_be_between_one_and_eighteen_digits
  validate :building_society_roll_number_must_be_in_a_valid_format

  validate :claim_must_not_be_ineligible, on: :submit

  validate :school_must_be_open, on: :submit

  before_save :normalise_trn, if: :teacher_reference_number_changed?
  before_save :normalise_ni_number, if: :national_insurance_number_changed?
  before_save :normalise_bank_account_number, if: :bank_account_number_changed?
  before_save :normalise_bank_sort_code, if: :bank_sort_code_changed?
  before_save :normalise_first_name, if: :first_name_changed?
  before_save :normalise_surname, if: :surname_changed?

  scope :unsubmitted, -> { where(submitted_at: nil) }
  scope :submitted, -> { where.not(submitted_at: nil) }
  scope :awaiting_decision, -> { submitted.joins("LEFT OUTER JOIN decisions ON decisions.claim_id = claims.id AND decisions.undone = false").where(decisions: {claim_id: nil}) }
  scope :awaiting_task, ->(task_name) { awaiting_decision.joins(sanitize_sql(["LEFT OUTER JOIN tasks ON tasks.claim_id = claims.id AND tasks.name = ?", task_name])).where(tasks: {claim_id: nil}) }
  scope :approved, -> { joins(:decisions).merge(Decision.active.approved) }
  scope :rejected, -> { joins(:decisions).merge(Decision.active.rejected) }
  scope :approaching_decision_deadline, -> { awaiting_decision.where("submitted_at < ? AND submitted_at > ?", DECISION_DEADLINE.ago + DECISION_DEADLINE_WARNING_POINT, DECISION_DEADLINE.ago) }
  scope :passed_decision_deadline, -> { awaiting_decision.where("submitted_at < ?", DECISION_DEADLINE.ago) }
  scope :payrollable, -> { approved.where(payment: nil) }
  scope :by_policy, ->(policy) { where(eligibility_type: policy::Eligibility.to_s) }
  scope :by_policies, ->(policies) { where(eligibility_type: policies.map { |p| p::Eligibility.to_s }) }
  scope :by_academic_year, ->(academic_year) { where(academic_year: academic_year) }
  scope :by_claims_team_member, ->(service_operator_id) { where(assigned_to_id: service_operator_id) }
  scope :unassigned, -> { where(assigned_to_id: nil) }
  scope :current_academic_year, -> { by_academic_year(AcademicYear.current) }

  delegate :award_amount, to: :eligibility
  delegate :scheduled_payment_date, to: :payment, allow_nil: true

  def submit!
    raise NotSubmittable unless submittable?

    self.submitted_at = Time.zone.now
    self.reference = unique_reference
    eligibility&.submit!
    save!
  end

  def submitted?
    submitted_at.present?
  end

  def submittable?
    valid?(:submit) && !submitted? && submittable_email_details? && submittable_mobile_details?
  end

  def approvable?
    submitted? && !payroll_gender_missing? && !decision_made? && !payment_prevented_by_other_claims?
  end

  def latest_decision
    decisions.active.last
  end

  def decision_made?
    latest_decision.present? && latest_decision.persisted?
  end

  def payroll_gender_missing?
    %w[male female].exclude?(payroll_gender)
  end

  def payment_prevented_by_other_claims?
    ClaimsPreventingPaymentFinder.new(self).claims_preventing_payment.any?
  end

  def decision_deadline_date
    (submitted_at + DECISION_DEADLINE).to_date
  end

  def deadline_warning_date
    (submitted_at + DECISION_DEADLINE - DECISION_DEADLINE_WARNING_POINT).to_date
  end

  def address(separator = ", ")
    Claim::ADDRESS_ATTRIBUTES.map { |attr| send(attr) }.reject(&:blank?).join(separator)
  end

  def no_student_loan?
    !has_student_loan?
  end

  def no_masters_doctoral_loan?
    has_masters_doctoral_loan == false
  end

  def student_loan_country_with_one_plan?
    StudentLoan::PLAN_1_COUNTRIES.include?(student_loan_country) || StudentLoan::PLAN_4_COUNTRIES.include?(student_loan_country)
  end

  # Returns true if the claim has a verified identity received from GOV.UK Verify.
  def identity_verified?
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

  def personal_data_removed?
    personal_data_removed_at.present?
  end

  def payrolled?
    payment.present?
  end

  def scheduled_for_payment?
    scheduled_payment_date.present?
  end

  def full_name
    [first_name, middle_name, surname].reject(&:blank?).join(" ")
  end

  def self.filtered_params
    FILTER_PARAMS.select { |_, v| v }.keys
  end

  def reset_dependent_answers
    ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_names|
      dependent_attribute_names.each do |dependent_attribute_name|
        write_attribute(dependent_attribute_name, nil) if changed.include?(attribute_name)
      end
    end
    self.student_loan_plan = determine_student_loan_plan
  end

  def policy
    eligibility&.policy
  end

  def school
    eligibility&.current_school
  end

  def amendable?
    submitted? && !payrolled? && !personal_data_removed?
  end

  def decision_undoable?
    decision_made? && !payrolled? && !personal_data_removed?
  end

  def has_ecp_policy?
    policy == EarlyCareerPayments
  end

  def has_tslr_policy?
    policy == StudentLoans
  end

  def has_lupp_policy?
    policy == LevellingUpPremiumPayments
  end

  def has_ecp_or_lupp_policy?
    has_ecp_policy? || has_lupp_policy?
  end

  def important_notes
    notes&.where(important: true)
  end

  def has_postgraduate_loan?
    [postgraduate_masters_loan, postgraduate_doctoral_loan].any?
  end

  private

  def normalise_trn
    self.teacher_reference_number = normalised_trn
  end

  def normalised_trn
    teacher_reference_number.gsub(/\D/, "")
  end

  def trn_must_be_seven_digits
    errors.add(:teacher_reference_number, "Teacher reference number must be 7 digits") if teacher_reference_number.present? && normalised_trn.length != TRN_LENGTH
  end

  def normalise_ni_number
    self.national_insurance_number = normalised_ni_number
  end

  def normalised_ni_number
    national_insurance_number.gsub(/\s/, "").upcase
  end

  def normalise_first_name
    first_name.strip!
  end

  def normalise_surname
    surname.strip!
  end

  def ni_number_is_correct_format
    errors.add(:national_insurance_number, "Enter a National Insurance number in the correct format") \
      if national_insurance_number.present? && !normalised_ni_number.match(/\A[A-Z]{2}[0-9]{6}[A-D]{1}\Z/)
  end

  def normalise_bank_account_number
    return if bank_account_number.nil?

    self.bank_account_number = normalised_bank_detail(bank_account_number)
  end

  def normalise_bank_sort_code
    return if bank_sort_code.nil?

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
      unless /\A[a-z0-9\-\s.\/]{1,18}\z/i.match?(building_society_roll_number)
  end

  def bank_account_number_must_be_eight_digits
    errors.add(:bank_account_number, "Account number must be 8 digits") \
      if bank_account_number.present? && normalised_bank_detail(bank_account_number) !~ /\A\d{8}\z/
  end

  def bank_sort_code_must_be_six_digits
    errors.add(:bank_sort_code, "Sort code must be 6 digits") \
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

  def school_must_be_open
    errors.add(:base, "The selected school is closed") if !school&.open?
  end

  def determine_student_loan_plan
    StudentLoan.determine_plan(has_student_loan?, has_postgraduate_loan?, student_loan_country, student_loan_start_date)
  end

  def postcode_is_valid
    unless postcode_is_valid?
      errors.add(:postcode, "Enter a postcode in the correct format")
    end
  end

  def postcode_is_valid?
    UKPostcode.parse(postcode).full_valid?
  end

  def date_has_day_month_year_components
    [
      date_of_birth_day,
      date_of_birth_month,
      date_of_birth_year
    ].compact.size
  end

  def date_of_birth_criteria
    if date_of_birth.present?
      errors.add(:date_of_birth, "Date of birth must be in the past") if date_of_birth > Time.zone.today
    else

      errors.add(:date_of_birth, "Date of birth must include a day, month and year in the correct format, for example 01 01 1980") if date_has_day_month_year_components.between?(1, 2)

      begin
        Date.new(date_of_birth_year, date_of_birth_month, date_of_birth_day) if date_has_day_month_year_components == 3
      rescue ArgumentError
        errors.add(:date_of_birth, "Enter a date of birth in the correct format")
      end

      errors.add(:date_of_birth, "Enter your date of birth") if errors[:date_of_birth].empty?
    end

    year = date_of_birth_year || date_of_birth&.year

    if year.present?
      if year < 1000
        errors.add(:date_of_birth, "Year must include 4 numbers")
      elsif year <= 1900
        errors.add(:date_of_birth, "Year must be after 1900")
      end
    end

    errors[:date_of_birth].empty?
  end

  def submittable_mobile_details?
    return true unless has_ecp_or_lupp_policy?
    return true if provide_mobile_number && mobile_number.present? && mobile_verified == true
    return true if provide_mobile_number == false && mobile_number.nil? && mobile_verified == false
    return true if provide_mobile_number == false && mobile_verified.nil?

    false
  end

  def submittable_email_details?
    email_address.present? && email_verified == true
  end
end
