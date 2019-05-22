class TslrClaim < ApplicationRecord
  PAGE_SEQUENCE = [
    "qts-year",
    "claim-school",
    "still-teaching",
    "current-school",
    "full-name",
    "address",
    "date-of-birth",
    "teacher-reference-number",
    "national-insurance-number",
    "email-address",
    "complete",
  ].freeze

  VALID_QTS_YEARS = [
    "2013-2014",
    "2014-2015",
    "2015-2016",
    "2016-2017",
    "2017-2018",
    "2018-2019",
    "2019-2020",
  ].freeze

  TRN_LENGTH = 7

  enum employment_status: {
    claim_school: 0,
    different_school: 1,
    no_school: 2,
  }, _prefix: :employed_at

  belongs_to :claim_school, optional: true, class_name: "School"
  belongs_to :current_school, optional: true, class_name: "School"

  validates :claim_school,              on: :"claim-school", presence: {message: "Select a school from the list"}
  validates :qts_award_year,            on: :"qts-year", inclusion: {in: VALID_QTS_YEARS, message: "Select the academic year you were awarded qualified teacher status"}
  validates :employment_status,         on: :"still-teaching", presence: {message: "Choose the option that describes your current employment status"}
  validates :full_name,                 on: :"full-name", presence: {message: "Enter your full name"}
  validates :address_line_1,            on: :address, presence: {message: "Enter your building and street address"}
  validates :address_line_3,            on: :address, presence: {message: "Enter your town or city"}
  validates :postcode,                  on: :address, presence: {message: "Enter your postcode"}, \
                                        length: {maximum: 11, message: "Postcode must be 11 characters or less"}
  validates :date_of_birth,             on: :"date-of-birth", presence: {message: "Enter your date of birth"}
  validates :teacher_reference_number,  on: :"teacher-reference-number", presence: {message: "Enter your teacher reference number"}
  validate :trn_must_be_seven_digits
  validates :national_insurance_number, on: :"national-insurance-number", presence: {message: "Enter your National Insurance number"}
  validate  :ni_number_is_correct_format
  validates :email_address, on: :"email-address", presence: {message: "Enter an email address"}
  validates :email_address, format: {with: URI::MailTo::EMAIL_REGEXP, message: "Enter an email address in the correct format, like name@example.com"}, \
                            length: {maximum: 256, message: "Email address must be 256 characters or less"}, \
                            allow_nil: true

  before_save :update_current_school, if: :employment_status_changed?
  before_save :normalise_trn, if: :teacher_reference_number_changed?
  before_save :normalise_ni_number, if: :national_insurance_number_changed?

  delegate :name, to: :claim_school, prefix: true, allow_nil: true

  def page_sequence
    PAGE_SEQUENCE.dup.tap do |sequence|
      sequence.delete("current-school") if employed_at_claim_school?
    end
  end

  def ineligible?
    ineligible_claim_school? || employed_at_no_school?
  end

  def ineligibility_reason
    [:ineligible_claim_school, :employed_at_no_school].find { |eligibility_check| send("#{eligibility_check}?") }
  end

  private

  def ineligible_claim_school?
    claim_school.present? && !claim_school.eligible_for_tslr?
  end

  def update_current_school
    self.current_school = employed_at_claim_school? ? claim_school : nil
  end

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
    national_insurance_number.gsub(/\s/, "")
  end

  def ni_number_is_correct_format
    errors.add(:national_insurance_number, "Enter a National Insurance number in the correct format") \
      if national_insurance_number.present? && !normalised_ni_number.match(/\A[a-z]{2}[0-9]{6}[a-d]{1}\Z/i)
  end
end
