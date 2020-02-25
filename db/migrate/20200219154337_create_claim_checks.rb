class CreateClaimChecks < ActiveRecord::Migration[6.0]
  def change
    create_table :checks, id: :uuid do |t|
      t.string :name
      t.references :claim, foreign_key: true, type: :uuid
      t.references :created_by, type: :uuid, foreign_key: {to_table: :dfe_sign_in_users}
      t.timestamps

      t.index [:name, :claim_id], unique: true
    end
  end
end
