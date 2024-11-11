# frozen_string_literal: true

class Claim < ApplicationRecord
  NO_STUDENT_LOAN = "not_applicable"
  STUDENT_LOAN_PLAN_OPTIONS = StudentLoan::PLANS.dup << NO_STUDENT_LOAN
  ADDRESS_ATTRIBUTES = %w[address_line_1 address_line_2 address_line_3 address_line_4 postcode].freeze
  AMENDABLE_ATTRIBUTES = %i[
    national_insurance_number
    date_of_birth
    student_loan_plan
    bank_sort_code
    bank_account_number
    building_society_roll_number
    address_line_1
    address_line_2
    address_line_3
    address_line_4
    postcode
  ].freeze
  FILTER_PARAMS = {
    address_line_1: true,
    address_line_2: true,
    address_line_3: true,
    address_line_4: true,
    postcode: true,
    payroll_gender: true,
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
    academic_year: false,
    personal_data_removed_at: false,
    email_verified: false,
    one_time_password: true,
    sent_one_time_password_at: false,
    mobile_verified: false,
    assigned_to_id: true,
    policy_options_provided: false,
    held: false,
    hmrc_bank_validation_responses: false,
    hmrc_bank_validation_succeeded: false,
    logged_in_with_tid: false,
    teacher_id_user_info: false,
    details_check: true,
    email_address_check: true,
    mobile_check: true,
    qa_required: false,
    qa_completed_at: false,
    qualifications_details_check: true,
    dqt_teacher_status: false,
    submitted_using_slc_data: false,
    journeys_session_id: false,
    column_to_remove_teacher_reference_number: true,
    identity_confirmed_with_onelogin: false,
    logged_in_with_onelogin: false,
    onelogin_credentials: true,
    onelogin_user_info: true,
    onelogin_uid: true,
    onelogin_auth_at: false,
    onelogin_idv_at: false,
    onelogin_idv_first_name: true,
    onelogin_idv_last_name: true,
    onelogin_idv_date_of_birth: true,
    paye_reference: true,
    practitioner_email_address: true,
    provider_contact_name: true,
    started_at: false,
    verified_at: false
  }.freeze
  DECISION_DEADLINE = 12.weeks
  DECISION_DEADLINE_WARNING_POINT = 2.weeks
  CLAIMANT_MATCHING_ATTRIBUTES = %i[
    national_insurance_number
  ]

  # Use AcademicYear as custom ActiveRecord attribute type
  attribute :academic_year, AcademicYear::Type.new

  attribute :date_of_birth_day, :integer
  attribute :date_of_birth_month, :integer
  attribute :date_of_birth_year, :integer

  enum student_loan_country: StudentLoan::COUNTRIES
  enum student_loan_start_date: StudentLoan::COURSE_START_DATES
  enum student_loan_courses: {one_course: 0, two_or_more_courses: 1}
  enum bank_or_building_society: {personal_bank_account: 0, building_society: 1}

  has_many :decisions, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :amendments, dependent: :destroy
  has_many :topups, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_one :support_ticket, dependent: :destroy

  belongs_to :eligibility, polymorphic: true, inverse_of: :claim, dependent: :destroy
  belongs_to :early_years_payment_eligibility,
    class_name: "Policies::EarlyYearsPayments::Eligibility",
    optional: true,
    foreign_key: :eligibility_id

  belongs_to :journey_session,
    optional: true,
    class_name: "Journeys::Session",
    inverse_of: :claim,
    foreign_key: :journeys_session_id

  accepts_nested_attributes_for :eligibility, update_only: true
  delegate :eligible_itt_subject, to: :eligibility, allow_nil: true

  has_many :claim_payments, dependent: :destroy
  has_many :payments, through: :claim_payments

  belongs_to :assigned_to, class_name: "DfeSignIn::User",
    inverse_of: :assigned_claims,
    optional: true

  enum payroll_gender: {
    dont_know: 0,
    female: 1,
    male: 2
  }

  validates :academic_year_before_type_cast, format: {with: AcademicYear::ACADEMIC_YEAR_REGEXP}

  validates :has_student_loan, on: [:"student-loan"], inclusion: {in: [true, false]}, allow_nil: true
  validates :student_loan_plan, inclusion: {in: STUDENT_LOAN_PLAN_OPTIONS}, allow_nil: true

  validates :bank_sort_code, on: [:amendment], presence: {message: "Enter a sort code"}
  validates :bank_account_number, on: [:amendment], presence: {message: "Enter an account number"}

  validates :payroll_gender, on: [:"payroll-gender-task"], presence: {message: "You must select a gender that will be passed to HMRC"}

  validate :bank_account_number_must_be_eight_digits
  validate :bank_sort_code_must_be_six_digits

  before_save :normalise_ni_number, if: %i[national_insurance_number national_insurance_number_changed?]
  before_save :normalise_bank_account_number, if: %i[bank_account_number bank_account_number_changed?]
  before_save :normalise_bank_sort_code, if: %i[bank_sort_code bank_sort_code_changed?]
  before_save :normalise_first_name, if: %i[first_name first_name_changed?]
  before_save :normalise_surname, if: %i[surname surname_changed?]

  scope :held, -> { where(held: true) }
  scope :not_held, -> { where(held: false) }
  scope :awaiting_decision, -> do
    joins("LEFT OUTER JOIN decisions ON decisions.claim_id = claims.id AND decisions.undone = false")
      .where(decisions: {claim_id: nil})
  end
  scope :awaiting_task, ->(task_name) { awaiting_decision.joins(sanitize_sql(["LEFT OUTER JOIN tasks ON tasks.claim_id = claims.id AND tasks.name = ?", task_name])).where(tasks: {claim_id: nil}) }
  scope :auto_approved, -> { approved.where(decisions: {created_by: nil}) }
  scope :approved, -> { joins(:decisions).merge(Decision.active.approved) }
  scope :rejected, -> { joins(:decisions).merge(Decision.active.rejected) }
  scope :approaching_decision_deadline, -> { awaiting_decision.where("submitted_at < ? AND submitted_at > ?", DECISION_DEADLINE.ago + DECISION_DEADLINE_WARNING_POINT, DECISION_DEADLINE.ago) }
  scope :passed_decision_deadline, -> { awaiting_decision.where("submitted_at < ?", DECISION_DEADLINE.ago) }
  scope :by_policy, ->(policy) { where(eligibility_type: policy::Eligibility.to_s) }
  scope :by_policies, ->(policies) { where(eligibility_type: policies.map { |p| p::Eligibility.to_s }) }
  scope :by_policies_for_journey, ->(journey) { by_policies(journey::POLICIES) }
  scope :by_academic_year, ->(academic_year) { where(academic_year: academic_year) }
  scope :assigned_to_team_member, ->(service_operator_id) { where(assigned_to_id: service_operator_id) }
  scope :by_claims_team_member, ->(service_operator_id, status) do
    if %w[approved approved_awaiting_payroll rejected].include?(status)
      assigned_to_team_member(service_operator_id).or(joins(:decisions).where(decisions: {created_by_id: service_operator_id}))
    else
      assigned_to_team_member(service_operator_id)
    end
  end
  scope :unassigned, -> { where(assigned_to_id: nil) }
  scope :current_academic_year, -> { by_academic_year(AcademicYear.current) }
  scope :failed_bank_validation, -> { where(hmrc_bank_validation_succeeded: false) }
  scope :unscrubbed, -> { where(personal_data_removed_at: nil) }

  scope :with_same_claimant, ->(claim) do
    CLAIMANT_MATCHING_ATTRIBUTES.reduce(where.not(id: claim.id)) do |scope, attr|
      scope.where(attr => claim.public_send(attr))
    end
  end

  delegate :award_amount, to: :eligibility

  scope :payrollable, -> { approved.not_awaiting_qa.left_joins(:payments).where(payments: nil) }
  scope :not_awaiting_qa, -> { approved.where("qa_required = false OR (qa_required = true AND qa_completed_at IS NOT NULL)") }
  scope :awaiting_qa, -> { approved.qa_required.where(qa_completed_at: nil) }
  scope :qa_required, -> { where(qa_required: true) }
  scope :awaiting_further_education_provider_verification, -> do
    joins("INNER JOIN further_education_payments_eligibilities ON further_education_payments_eligibilities.id = claims.eligibility_id")
      .left_outer_joins(:notes)
      .where("further_education_payments_eligibilities.verification = '{}'")
      .and(
        Claim.where("further_education_payments_eligibilities.flagged_as_duplicate = FALSE")
        .or(Claim.where("further_education_payments_eligibilities.flagged_as_duplicate = TRUE").and(Claim.where(notes: {label: "provider_verification"})))
      )
  end
  scope :not_awaiting_further_education_provider_verification, -> do
    where.not(id: Claim.awaiting_further_education_provider_verification)
  end

  scope :with_award_amounts, -> do
    joins(
      <<~SQL
        JOIN (
          #{
            Policies::POLICIES.map do |policy|
              "
                SELECT
                id,
                #{policy.award_amount_column} AS award_amount,
                '#{policy::Eligibility}' AS eligibility_type
                FROM #{policy::Eligibility.table_name}
              "
            end.join(" UNION ALL ")
          }
        ) AS eligibilities
        ON claims.eligibility_id = eligibilities.id
        AND claims.eligibility_type = eligibilities.eligibility_type
      SQL
    )
  end

  scope :require_in_progress_update_emails, -> {
    by_policies(Policies.all.select{|p| p.require_in_progress_update_emails? })
  }

  def onelogin_idv_full_name
    "#{onelogin_idv_first_name} #{onelogin_idv_last_name}"
  end

  def hold!(reason:, user:)
    if holdable? && !held?
      self.class.transaction do
        update!(held: true)
        notes.create!(body: "Claim put on hold: #{reason}", created_by: user)
      end
    end
  end

  def unhold!(user:)
    if held?
      self.class.transaction do
        update!(held: false)
        notes.create!(body: "Claim hold removed", created_by: user)
      end
    end
  end

  def submitted?
    submitted_at.present?
  end

  def submittable?
    valid?(:submit) && !submitted? && submittable_email_details? && submittable_mobile_details?
  end

  def approvable?
    submitted? &&
      !held? &&
      !payroll_gender_missing? &&
      (!decision_made? || awaiting_qa?) &&
      !payment_prevented_by_other_claims? &&
      attributes_flagged_by_risk_indicator.none? &&
      policy.approvable?(self)
  end

  def rejectable?
    !held?
  end

  def holdable?
    !decision_made?
  end

  def flaggable_for_qa?
    decision_made? && latest_decision.approved? && below_min_qa_threshold? && !awaiting_qa? && !qa_completed?
  end

  # This method's intention is to help make a decision on whether a claim should
  # be flagged for QA or not. These criteria need to be met for each academic year:
  #
  # 1. the first claim to be approved should always be flagged for QA
  # 2. subsequently approved claims should be flagged for QA, 1 in 100/MIN_QA_THRESHOLD.
  #
  # This method should be used every time a new approval decision is being made;
  # when used retrospectively, i.e. when several claims have been approved,
  # the method returns:
  #
  # 1. `true` if none of then claims have been flagged for QA
  # 2. `true` if some claims have been flagged for QA using a lower MIN_QA_THRESHOLD
  # 3. `false` if some claims have been flagged for QA using a higher MIN_QA_THRESHOLD
  #
  # Newly approved claims should not be flagged for QA for as long as the method
  # returns `false`; they should be flagged for QA otherwise.
  def below_min_qa_threshold?
    return false if policy::MIN_QA_THRESHOLD.zero?

    approved_claims = Claim.by_policy(policy).by_academic_year(academic_year).approved
    claims_approved_so_far = approved_claims.count
    return true if claims_approved_so_far.zero?

    (approved_claims.qa_required.count.to_f / claims_approved_so_far) * 100 <= policy::MIN_QA_THRESHOLD
  end

  def qa_completed?
    qa_completed_at?
  end

  def awaiting_qa?
    qa_required? && !qa_completed?
  end

  def latest_decision
    decisions.active.last
  end

  def previous_decision
    decisions.last(2).first
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
    policy.decision_deadline_date(self)
  end

  def address(separator = ", ")
    Claim::ADDRESS_ATTRIBUTES.map { |attr| send(attr) }.reject(&:blank?).join(separator)
  end

  # Returns true if the claim has a verified identity received from GOV.UK Verify.
  # TODO: We no longer use GOV.UK Verify these verified? methods aren't used anymore.
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
    payments.present?
  end

  def all_payrolled?
    if has_lupp_policy?
      topups.all? { |t| t.payrolled? } && payrolled?
    else
      payrolled?
    end
  end

  def topupable?
    has_lupp_policy? && submitted? && all_payrolled?
  end

  def full_name
    [first_name, middle_name, surname].reject(&:blank?).join(" ")
  end

  def self.filtered_params
    FILTER_PARAMS.select { |_, v| v }.keys
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
    policy == Policies::EarlyCareerPayments
  end

  def has_tslr_policy?
    policy == Policies::StudentLoans
  end

  def has_lupp_policy?
    policy == Policies::LevellingUpPremiumPayments
  end

  def has_ecp_or_lupp_policy?
    has_ecp_policy? || has_lupp_policy?
  end

  def has_early_years_payments_policy?
    policy == Policies::EarlyYearsPayments
  end

  def important_notes
    notes&.where(important: true)
  end

  def award_amount_with_topups
    topups.sum(:award_amount) + (award_amount || 0)
  end

  def must_manually_validate_bank_details?
    !hmrc_bank_validation_succeeded?
  end

  def submitted_without_slc_data?
    # FE claims prior to the deployment of LUPEYALPHA-1010 have submitted_using_slc_data = nil
    submitted_using_slc_data != true
  end

  def has_dqt_record?
    !dqt_teacher_status.blank?
  end

  def dqt_teacher_record
    policy::DqtRecord.new(Dqt::Teacher.new(dqt_teacher_status), eligibility) if has_dqt_record?
  end

  def same_claimant?(other_claim)
    CLAIMANT_MATCHING_ATTRIBUTES.all? do |attr|
      public_send(attr) == other_claim.public_send(attr)
    end
  end

  def one_login_idv_mismatch?
    !one_login_idv_name_match? || !one_login_idv_dob_match?
  end

  def one_login_idv_match?
    one_login_idv_name_match? && one_login_idv_dob_match?
  end

  def awaiting_provider_verification?
    return false unless has_further_education_policy?

    eligibility.awaiting_provider_verification?
  end

  def has_early_years_policy?
    policy == Policies::EarlyYearsPayments
  end

  def attributes_flagged_by_risk_indicator
    @attributes_flagged_by_risk_indicator ||= RiskIndicator.flagged_attributes(self)
  end

  private

  def one_login_idv_name_match?
    onelogin_idv_full_name.downcase == "#{first_name.downcase} #{surname.downcase}"
  end

  def one_login_idv_dob_match?
    onelogin_idv_date_of_birth == date_of_birth
  end

  def has_further_education_policy?
    policy == Policies::FurtherEducationPayments
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

  def bank_account_number_must_be_eight_digits
    errors.add(:bank_account_number, "Account number must be 8 digits") if bank_account_number.present? && normalised_bank_detail(bank_account_number) !~ /\A\d{8}\z/
  end

  def bank_sort_code_must_be_six_digits
    errors.add(:bank_sort_code, "Sort code must be 6 digits") if bank_sort_code.present? && normalised_bank_detail(bank_sort_code) !~ /\A\d{6}\z/
  end

  def using_mobile_number_from_tid?
    logged_in_with_tid? && mobile_check == "use" && provide_mobile_number && mobile_number.present?
  end

  def submittable_mobile_details?
    return true if using_mobile_number_from_tid?
    return true if provide_mobile_number && mobile_number.present? && mobile_verified == true
    return true if provide_mobile_number == false && mobile_number.nil? && mobile_verified == false
    return true if provide_mobile_number == false && mobile_verified.nil?

    false
  end

  def submittable_email_details?
    email_address.present? && email_verified == true
  end
end
