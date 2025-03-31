class Decision < ApplicationRecord
  belongs_to :claim
  belongs_to :created_by, class_name: "DfeSignIn::User", optional: true

  delegate :policy, to: :claim

  REJECTED_REASONS = Policies.all.flat_map do |policy|
    policy::ADMIN_DECISION_REJECTED_REASONS
  end.uniq

  store_accessor :rejected_reasons, *REJECTED_REASONS, prefix: true

  # NOTE: Don't store the rejected_reasons data params from the form when Approve is selected
  before_validation :clear_rejected_reasons, unless: :rejected?

  validates :approved, inclusion: {
    in: [true, false],
    message: "Make a decision to approve or reject the claim"
  }
  validate :claim_must_be_approvable, if: :approved?, on: :create
  validate :claim_must_be_rejectable, if: :rejected?, on: :create
  validate :claim_must_have_undoable_decision, if: :undone?, on: :update
  validate :rejected_reasons_required, if: -> { !undone? && rejected? }
  validate :rejected_reasons_selectable, if: :rejected?
  validates :notes, if: -> { rejected? && rejected_reasons_other? }, presence: {message: "You must enter a reason for rejecting this claim in the decision note"}
  validates :notes, if: -> { !created_by_id? }, presence: {message: "You must add a note when the decision is automated"}

  scope :active, -> { where(undone: false) }
  scope :approved, -> { where(approved: true) }
  scope :rejected, -> { where(approved: false) }

  self.ignored_columns = %w[result]

  def rejected?
    !approved? && !approved.nil?
  end

  def result
    return nil if approved.nil?

    approved ? "approved" : "rejected"
  end

  def self.rejected_reasons_for(claim)
    claim.policy.rejected_reasons(claim)
  end

  def readonly?
    return false if destroyed_by_association
    persisted? && !undone
  end

  def rejected_reasons_hash
    policy::ADMIN_DECISION_REJECTED_REASONS.reduce({}) do |memo, reason|
      memo.merge("reason_#{reason}": public_send(:"rejected_reasons_#{reason}") || "0")
    end
  end

  def selected_rejected_reasons
    return [] if rejected_reasons.nil?

    rejected_reasons.select { |_, value| value == "1" }.keys.map(&:to_sym)
  end

  private

  def claim_must_be_approvable
    errors.add(:base, "This claim cannot be approved") unless claim.approvable?
  end

  def claim_must_be_rejectable
    errors.add(:base, "This claim cannot be rejected") unless claim.rejectable?
  end

  def claim_must_have_undoable_decision
    errors.add(:base, "This claim cannot have its decision undone") unless claim.decision_undoable?
  end

  # NOTE: as rejected_reasons are stored as JSONB, question mark methods and converting to boolean rails magic isn't available
  def rejected_reasons_other?
    rejected_reasons_other == "1"
  end

  def rejected_reasons_required
    return if rejected_reasons.value?("1")

    errors.add(:rejected_reasons, "At least one reason is required")
  end

  def rejected_reasons_selectable
    available_rejected_reasons = self.class.rejected_reasons_for(claim)
    return if (selected_rejected_reasons - available_rejected_reasons).empty?

    errors.add(:rejected_reasons, "One or more reasons are not selectable for this claim")
  end

  def clear_rejected_reasons
    REJECTED_REASONS.each do |r|
      send(:"rejected_reasons_#{r}=", nil)
    end
  end
end
