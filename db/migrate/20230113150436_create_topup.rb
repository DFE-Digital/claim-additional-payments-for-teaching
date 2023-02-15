class CreateTopup < ActiveRecord::Migration[6.1]
  def change
    create_table :topups, id: :uuid do |t|
      t.references :claim, type: :uuid, foreign_key: true
      t.decimal :award_amount, precision: 7, scale: 2
      t.references :payment, type: :uuid, foreign_key: true
      t.references :dfe_sign_in_users, :created_by, type: :uuid, foreign_key: {to_table: :dfe_sign_in_users}

      t.timestamps
    end

    add_index :topups, [:claim_id, :payment_id], unique: true
  end
end
