class Note < ApplicationRecord
  belongs_to :claim

  validates :body, :created_by, presence: true
end
