# A service operator can amend a claim. When they do so, an Amendment record is
# created. The amendments of a claim provide an audit trail which explains why
# the claim has its current attribute values. It stores the details of which
# attributes were changed, and optionally their old and new values.
#
# The claim_changes attribute is a hash whose keys (String) are the names of
# the attributes changed. The values are either
# - an array [old_value, new_value]
# - nil, meaning that this personal data has been removed from the amendment
class Amendment < ApplicationRecord
  belongs_to :claim
  belongs_to :created_by, class_name: "DfeSignIn::User"
  serialize :claim_changes, Hash

  validates :claim_changes, presence: {message: "To amend the claim you must change at least one value"}
  validates :notes, presence: {message: "Enter a message to explain why you are making this amendment"}
  validate :claim_must_be_amendable, on: :create

  # Updates the claim using the attributes given in claim_attributes, and uses
  # these changes to create an associated Amendment record with additional
  # attributes given by amendment_attributes.
  #
  # If the operation fails, then the claim’s changes will not be persisted, and
  # the Amendment record will not be saved.
  #
  # Returns an Amendment record.
  # - If the operation was successful, this will return true for persisted?
  # - If the operation failed, this will return false for persisted?, and the
  # amendment’s errors will have been populated with the errors from the claim.
  def self.amend_claim(claim, claim_attributes, amendment_attributes)
    amendment = Amendment.new(claim: claim, **amendment_attributes)

    Claim.transaction do
      claim.assign_attributes(claim_attributes)

      unless claim.save(context: [:submit, :amendment])
        amendment.valid?
        amendment.errors.merge!(claim.errors)
        amendment.errors.delete(:claim_changes)
        raise ActiveRecord::Rollback
      end

      changes_hash = claim.previous_changes.merge(claim.eligibility.previous_changes)
        .slice(*Claim::AMENDABLE_ATTRIBUTES + Claim::AMENDABLE_ELIGIBILITY_ATTRIBUTES)
        .reject { |_, values| values.all?(&:blank?) }
        .to_h

      amendment.claim_changes = changes_hash

      raise ActiveRecord::Rollback unless amendment.save
    end

    amendment
  end

  private

  def claim_must_be_amendable
    errors.add(:claim, "must be amendable") unless claim.amendable?
  end
end
