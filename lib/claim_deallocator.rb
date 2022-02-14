class ClaimDeallocator
  attr_reader :claim_ids, :admin_user_id, :bulk

  def initialize(claim_ids:, admin_user_id:, bulk: false)
    @claim_ids = claim_ids
    @admin_user_id = admin_user_id
    @bulk = bulk
  end

  def call
    if bulk == false
      Claim.where(id: claim_ids, assigned_to: admin_user_id)
        .update_all(assigned_to_id: nil)
    elsif bulk == true
      Claim.where(assigned_to_id: admin_user_id)
        .update_all(assigned_to_id: nil)
    end
  end
end
