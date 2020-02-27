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

  validates :policy_type, inclusion: {in: Policies.all.map(&:name)}
  validates :current_academic_year_before_type_cast, format: {with: ACADEMIC_YEAR_REGEXP}

  def self.for(policy)
    find_by policy_type: policy.name
  end

  def policy
    policy_type.constantize
  end
end
