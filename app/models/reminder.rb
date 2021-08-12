class Reminder < ApplicationRecord
  include ::OneTimePasswordCheckable

  SLUGS = %w[
    personal-details
    email-verification
    set
  ].freeze

  validates :full_name, on: [:"personal-details"], presence: {message: "Enter your full name"}
  validates :full_name, length: {maximum: 100, message: "Full name must be 100 characters or less"}

  validates :email_address, on: [:"personal-details"], presence: {message: "Enter an email address"}
  validates :email_address, format: {with: URI::MailTo::EMAIL_REGEXP, message: "Enter an email in the format name@example.com"},
                            length: {maximum: 256, message: "Email address must be 256 characters or less"}


  def self.email_verified
    where(email_verified: true)  
  end

  def self.not_yet_sent
    email_verified.where(email_sent_at: nil)
  end
end
