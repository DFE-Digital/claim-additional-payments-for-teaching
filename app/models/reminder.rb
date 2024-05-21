class Reminder < ApplicationRecord
  attribute :sent_one_time_password_at, :datetime
  attribute :one_time_password, :string, limit: 6

  scope :email_verified, -> { where(email_verified: true) }
  scope :not_yet_sent, -> { where(email_sent_at: nil) }
  scope :inside_academic_year, -> { where(itt_academic_year: AcademicYear.current.to_s) }
  scope :to_be_sent, -> { email_verified.not_yet_sent.inside_academic_year }

  def self.set_a_reminder?(policy_year:, itt_academic_year:)
    return false if policy_year >= EligibilityCheckable::FINAL_COMBINED_ECP_AND_LUP_POLICY_YEAR

    next_year = policy_year + 1
    eligible_itt_years = JourneySubjectEligibilityChecker.selectable_itt_years_for_claim_year(next_year)
    eligible_itt_years.include?(itt_academic_year)
  end

  def send_year
    itt_academic_year.start_year
  end

  def itt_academic_year
    AcademicYear.new(
      read_attribute(:itt_academic_year)
    )
  end
end
