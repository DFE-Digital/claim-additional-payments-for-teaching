class SupportTicket < ApplicationRecord
  belongs_to :claim
  belongs_to :created_by, class_name: "DfeSignIn::User"

  validates :claim, :created_by, presence: true
end
