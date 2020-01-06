class UpdatePayrollRunCreatedByToCreatedById < ActiveRecord::Migration[6.0]
  def up
    PayrollRun.all.each do |payroll_run|
      user_id = payroll_run.read_attribute(:created_by)
      user = DfeSignIn::User.find_or_create_by(dfe_sign_in_id: user_id)
      payroll_run.update_column(:created_by_id, user.id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
