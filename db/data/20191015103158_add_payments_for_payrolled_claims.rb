class AddPaymentsForPayrolledClaims < ActiveRecord::Migration[5.2]
  def up
    claims = Claim.left_outer_joins(:payment)
      .where("payments.id IS NULL AND claims.payroll_run_id IS NOT NULL")

    claims.each do |claim|
      Payment.create!(payroll_run_id: claim.payroll_run_id, claim: claim, award_amount: claim.award_amount)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
