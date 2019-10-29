class RemovePayrollRunIdFromClaim < ActiveRecord::Migration[5.2]
  def change
    remove_reference :claims, :payroll_run
  end
end
