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
end
