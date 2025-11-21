module Admin
  class ClaimAllocator
    attr_reader :claim_ids, :admin_user_id

    def initialize(claim_ids:, admin_user_id:)
      @claim_ids = claim_ids
      @admin_user_id = admin_user_id
    end

    def call
      # Avoid users clashing
      Claim
        .where(id: claim_ids, assigned_to: nil)
        .update(assigned_to_id: admin_user_id)
    end
  end
end
