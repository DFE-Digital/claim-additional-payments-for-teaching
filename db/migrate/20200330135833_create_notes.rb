class CreateNotes < ActiveRecord::Migration[6.0]
  def change
    create_table :notes, id: :uuid do |t|
      t.string :body
      t.references :claim, foreign_key: true, type: :uuid
      t.references :created_by, type: :uuid, foreign_key: {to_table: :dfe_sign_in_users}
      t.timestamps

      t.index [:claim_id, :created_at], unique: true
    end
  end
end
