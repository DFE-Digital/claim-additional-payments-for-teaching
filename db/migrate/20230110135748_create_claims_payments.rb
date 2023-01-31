class CreateClaimsPayments < ActiveRecord::Migration[6.1]
  def up
    create_table :claims_payments, id: :uuid do |t|
      t.references :claim, type: :uuid, foreign_key: true
      t.references :payment, type: :uuid, foreign_key: true

      t.timestamps
    end
    add_index :claims_payments, [:claim_id, :payment_id], unique: true

    execute("INSERT INTO claims_payments (claim_id, payment_id, created_at, updated_at) SELECT id AS claim_id, payment_id, created_at, created_at FROM claims WHERE payment_id IS NOT NULL")

    # NOTE: requires future migration to drop this column, kept in case of an issue and rollback is required
    rename_column :claims, :payment_id, :remove_column_payment_id
  end

  def down
    drop_table :claims_payments

    rename_column :claims, :remove_column_payment_id, :payment_id
  end
end
