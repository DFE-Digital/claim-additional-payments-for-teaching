class Decision < ApplicationRecord
  belongs_to :claim
  belongs_to :created_by, class_name: "DfeSignIn::User"

  validates :result, :created_by, presence: {message: "Make a decision to approve or reject the claim"}
  validate :claim_must_be_approvable, if: :approved?, on: :create
  validate :claim_must_have_undoable_decision, if: :undone?, on: :update

  scope :active, -> { where(undone: false) }

  enum result: {
    approved: 0,
    rejected: 1
  }

  def readonly?
    persisted? && !undone
  end

  def number_of_days_since_claim_submitted
    (created_at.to_date - claim.submitted_at.to_date).to_i
  end

  private

  def claim_must_be_approvable
    errors.add(:base, "This claim cannot be approved") unless claim.approvable?
  end

  def claim_must_have_undoable_decision
    errors.add(:base, "This claim cannot have its decision undone") unless claim.decision_undoable?
  end
end
