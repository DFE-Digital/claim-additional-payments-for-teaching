class Note < ApplicationRecord
  belongs_to :claim
  belongs_to :created_by, class_name: "DfeSignIn::User"

  validates :created_by, presence: true
  validates :body, presence: {message: "Enter a note"}
end
