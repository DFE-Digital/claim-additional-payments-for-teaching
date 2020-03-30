class Note < ApplicationRecord
  belongs_to :claim
  belongs_to :created_by, class_name: "DfeSignIn::User"

  validates :body, :created_by, presence: true
end
