class Note < ApplicationRecord
  belongs_to :claim
  belongs_to :created_by, class_name: "DfeSignIn::User", optional: true

  validates :body, presence: {message: "Enter a note"}
end
