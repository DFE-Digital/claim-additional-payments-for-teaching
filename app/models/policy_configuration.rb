class PolicyConfiguration < ApplicationRecord
  validates :policy_type, inclusion: {in: Policies.all.map(&:name)}

  def policy
    policy_type.constantize
  end
end
