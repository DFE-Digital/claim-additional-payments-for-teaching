class SupportTicket < ApplicationRecord
  belongs_to :claim
  belongs_to :created_by, class_name: "DfeSignIn::User"

  validates :claim, :created_by, presence: true
  validates :url, url: {message: "Enter a valid support ticket URL"}
end
