class Check < ApplicationRecord
  belongs_to :claim

  validates :result, :checked_by, presence: true

  enum result: {
    approved: 0,
    rejected: 1,
  }

  def readonly?
    persisted?
  end
end
