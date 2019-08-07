class AddPayrollGenderToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :payroll_gender, :integer
  end
end
