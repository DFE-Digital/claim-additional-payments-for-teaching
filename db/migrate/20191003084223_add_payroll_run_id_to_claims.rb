class AddPayrollRunIdToClaims < ActiveRecord::Migration[5.2]
  def change
    change_table :claims do |t|
      t.references :payroll_run, foreign_key: true, type: :uuid
    end
  end
end
