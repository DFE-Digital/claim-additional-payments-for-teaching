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
  validates :policy_type, inclusion: {in: Policies.all.map(&:name)}

  def policy
    policy_type.constantize
  end
end
