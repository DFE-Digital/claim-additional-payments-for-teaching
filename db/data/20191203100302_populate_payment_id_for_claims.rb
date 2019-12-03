class PopulatePaymentIdForClaims < ActiveRecord::Migration[6.0]
  def up
    Claim.connection.execute("UPDATE claims SET payment_id = payments.id FROM payments WHERE payments.claim_id = claims.id")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
