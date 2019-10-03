class CreatePayrollRuns < ActiveRecord::Migration[5.2]
  def change
    create_table :payroll_runs, id: :uuid do |t|
      t.string :created_by, null: false
      t.timestamps index: true
    end
  end
end
