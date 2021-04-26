# frozen_string_literal: true

# Tasks are performed against a claim by service operators. Only one task of a
# particular type can be carried out per claim. These tasks were designed to
# make the process of checking a claim more granular.
#
# It records who completed the task and the date/time the action was carried
# out.
class Task < ApplicationRecord
  NAMES = %w[
    identity_confirmation
    qualifications
    employment
    student_loan_amount
    matching_details
    payroll_gender
  ].freeze

  belongs_to :claim
  belongs_to :created_by, class_name: "DfeSignIn::User", optional: true

  validates :name, uniqueness: {scope: :claim_id}, inclusion: {in: NAMES, message: "name not recognised"}
  validates_inclusion_of :passed, in: [true, false], message: "You must select ‘Yes’ or ‘No’"
  validates_inclusion_of :manual, in: [true, false]
end
