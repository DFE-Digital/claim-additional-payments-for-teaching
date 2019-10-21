class Check < ApplicationRecord
  belongs_to :claim

  validates :result, :checked_by, presence: {message: "Make a decision to approve or reject the claim"}

  enum result: {
    approved: 0,
    rejected: 1,
  }

  def readonly?
    persisted?
  end
end
