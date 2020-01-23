class Check < ApplicationRecord
  belongs_to :claim
  belongs_to :checked_by, class_name: "DfeSignIn::User"

  validates :result, :checked_by, presence: {message: "Make a decision to approve or reject the claim"}
  validate :claim_must_be_approvable, if: :approved?, on: :create

  enum result: {
    approved: 0,
    rejected: 1,
  }

  def readonly?
    persisted?
  end

  def number_of_days_since_claim_submitted
    (claim.check.created_at.to_date - claim.submitted_at.to_date).to_i
  end

  private

  def claim_must_be_approvable
    errors.add(:base, "This claim cannot be approved") unless claim.approvable?
  end
end
