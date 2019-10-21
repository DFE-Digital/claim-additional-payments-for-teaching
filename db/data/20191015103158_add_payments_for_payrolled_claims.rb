class AddPaymentsForPayrolledClaims < ActiveRecord::Migration[5.2]
  def up
    Claim.where.not(payroll_run_id: nil).each do |claim|
      claim.update!(payroll_run: PayrollRun.find(claim.payroll_run_id))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
