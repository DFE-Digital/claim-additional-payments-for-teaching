# frozen_string_literal: true

# Tasks are performed against a claim by service operators. Only one task of a
# particular type can be carried out per claim. These tasks were designed to
# make the process of checking a claim more granular.
#
# It records who completed the task and the date/time the action was carried
# out.
class Task < ApplicationRecord
  NAMES = %w[
    previous_payment
    identity_confirmation
    provider_verification
    visa
    arrival_date
    qualifications
    induction_confirmation
    census_subjects_taught
    employment
    employment_contract
    employment_start
    subject
    student_loan_amount
    student_loan_plan
    teaching_hours
    payroll_details
    matching_details
    payroll_gender
  ].freeze

  belongs_to :claim
  belongs_to :created_by, class_name: "DfeSignIn::User", optional: true

  enum claim_verifier_match: {none: 0, any: 1, all: 2}, _prefix: :claim_verifier_match

  validates :name, uniqueness: {scope: :claim_id}, inclusion: {in: NAMES, message: "name not recognised"}
  validates_inclusion_of :passed, in: [true, false], message: "You must select ‘Yes’ or ‘No’", on: :create
  validates :passed, allow_nil: true, inclusion: {in: [true, false]}, on: :claim_verifier
  validates :claim_verifier_match, allow_nil: true, inclusion: {in: claim_verifier_matches.keys}
  validates :manual, allow_nil: true, inclusion: {in: [true, false]}

  scope :automated, -> { where(manual: false) }
  scope :passed_automatically, -> { automated.where(passed: true) }

  scope :census_subjects_taught, -> { where(name: "census_subjects_taught") }
  scope :no_data_census_subjects_taught, -> { census_subjects_taught.where(passed: nil, claim_verifier_match: nil) }

  def to_param
    name
  end

  def identity_confirmation?
    name == "identity_confirmation"
  end
end
