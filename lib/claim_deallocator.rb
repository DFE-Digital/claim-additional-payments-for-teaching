class ClaimDeallocator
  attr_reader :claim_ids, :admin_user_id

  def initialize(claim_ids:, admin_user_id:)
    @claim_ids = claim_ids
    @admin_user_id = admin_user_id
  end

  def call
    Claim.where(id: claim_ids, assigned_to: admin_user_id).update(assigned_to_id: nil)
  end
end
