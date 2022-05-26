# Policy-specific configuration, managed through the service operator's admin
# interface.
#
# Things that are currently configurable:
#
# * open_for_submissions: defines whether the policy is currently accepting
#   claims or not
# * availability_message: an optional message that is shown to users when the
#   policy is closed for submissions
# * current_academic_year: the academic year the service is currently accepting
#   claims for.
class PolicyConfiguration < ApplicationRecord
  ACADEMIC_YEAR_REGEXP = /\A20\d{2}\/20\d{2}\z/.freeze

  # Use AcademicYear as custom ActiveRecord attribute type
  attribute :current_academic_year, AcademicYear::Type.new

  validates :current_academic_year_before_type_cast, format: {with: ACADEMIC_YEAR_REGEXP}

  def self.for(policy)
    where("? = ANY (policy_types)", policy.name).first
  end

  # TODO: Journey class can be merged into PolicyConfiguration, it's really serving the same purpose
  def routing_name
    Journey.routing_name_for_policy(policy_types.first.constantize)
  end

  # TODO: Eventually this shouldn't be used
  def early_career_payments?
    policy_types.include?(EarlyCareerPayments.name)
  end
end
