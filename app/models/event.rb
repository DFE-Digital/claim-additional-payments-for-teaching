class Event < ApplicationRecord
  belongs_to :claim
  belongs_to :actor, class_name: "DfeSignIn::User", optional: true
  belongs_to :entity, polymorphic: true, optional: true

  CLAIM = %w[
    claim_submitted
    claim_hold
    claim_unhold
    claim_approved
    claim_rejected
    claim_payrolled
    claim_amendment
    claim_assigned
    claim_unassigned
  ].freeze

  EMAILS = %w[
    email_rejected_sent
    email_confirmation_single_sent
    email_confirmation_multiple_sent
    email_three_week_old_undecided_sent
  ].freeze

  FE = %w[
    claim_fe_provider_verification_started
    claim_fe_provider_verification_completed
  ]

  EY = %w[
    email_ey_practitioner_sent
    email_ey_rejected_provider_sent
  ]

  TASKS = Task::NAMES.flat_map do |name|
    ["task_#{name}_false", "task_#{name}_true"]
  end.freeze

  OTHER_TASKS = %w[
    note_created
    task_qa_completed
    task_qa_required
  ].freeze

  NAMES = (CLAIM + EMAILS + TASKS + OTHER_TASKS + FE + EY).freeze

  validates :name, inclusion: {in: NAMES}
end
