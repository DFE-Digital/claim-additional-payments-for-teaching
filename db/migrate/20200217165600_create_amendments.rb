class CreateAmendments < ActiveRecord::Migration[6.0]
  def change
    create_table :amendments, id: :uuid do |t|
      t.references :claim, foreign_key: true, type: :uuid
      t.text :notes
      t.string :claim_changes
      t.references :dfe_sign_in_users, :created_by, type: :uuid, foreign_key: {to_table: :dfe_sign_in_users}

      t.timestamps
      t.timestamp :personal_data_removed_at
    end
  end
end
