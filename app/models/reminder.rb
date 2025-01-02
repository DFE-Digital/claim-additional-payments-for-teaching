class Reminder < ApplicationRecord
  include Deletable

  attribute :sent_one_time_password_at, :datetime
  attribute :one_time_password, :string, limit: 6

  scope :email_verified, -> { where(email_verified: true) }
  scope :not_yet_sent, -> { where(email_sent_at: nil) }
  scope :by_journey, ->(journey) { where(journey_class: journey.to_s) }
  scope :inside_academic_year, -> { where(itt_academic_year: AcademicYear.current.to_s) }
  scope :to_be_sent, -> { email_verified.not_yet_sent.inside_academic_year }

  def journey
    journey_class.constantize
  end

  def send_year
    itt_academic_year.start_year
  end

  def itt_academic_year
    AcademicYear.new(
      read_attribute(:itt_academic_year)
    )
  end

  def soft_delete!
    update!(deleted_at: Time.now)
  end
end
