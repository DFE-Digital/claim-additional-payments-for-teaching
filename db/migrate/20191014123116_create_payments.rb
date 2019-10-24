class CreatePayments < ActiveRecord::Migration[5.2]
  def change
    create_table :payments, id: :uuid do |t|
      t.references :claim, type: :uuid, foreign_key: true, index: {unique: true}
      t.references :payroll_run, type: :uuid, foreign_key: true
      t.decimal :award_amount, precision: 7, scale: 2
      t.timestamps
    end
  end
end
