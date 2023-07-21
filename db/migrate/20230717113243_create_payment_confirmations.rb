class CreatePaymentConfirmations < ActiveRecord::Migration[7.0]
  def up
    create_table :payment_confirmations, id: :uuid do |t|
      t.references :payroll_run, type: :uuid, foreign_key: true
      t.references :created_by, type: :uuid, foreign_key: {to_table: :dfe_sign_in_users}
      t.date :scheduled_payment_date, null: false

      t.timestamps
    end
  end

  def down
    drop_table :payment_confirmations
  end
end
