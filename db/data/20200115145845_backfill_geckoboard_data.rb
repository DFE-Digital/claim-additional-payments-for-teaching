class BackfillGeckoboardData < ActiveRecord::Migration[6.0]
  def up
    submitted_claim_ids = Claim.submitted.pluck(:id)
    paid_claim_ids = PayrollRun.where.not(scheduled_payment_date: nil).map(&:claims).flatten.pluck(:id)

    RecordClaimEventJob.perform_later(submitted_claim_ids, :submitted, :submitted_at)
    RecordClaimEventJob.perform_later(paid_claim_ids, :paid, :scheduled_payment_date)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
