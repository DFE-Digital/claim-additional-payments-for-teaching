class BackfillGeckoboardData < ActiveRecord::Migration[6.0]
  def up
    return unless defined?(BackfillGeckoboardDataJob)

    submitted_claims = Claim.submitted.all.map { |claim|
      {
        reference: claim.reference,
        policy: claim.policy.to_s,
        performed_at: claim.submitted_at,
      }
    }

    paid_claims = Payment.all.map { |payment|
      {
        reference: payment.claim.reference,
        policy: payment.claim.policy.to_s,
        performed_at: payment.updated_at,
      }
    }

    BackfillGeckoboardDataJob.perform_later("submitted", submitted_claims)
    BackfillGeckoboardDataJob.perform_later("paid", paid_claims)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
