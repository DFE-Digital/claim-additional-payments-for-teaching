class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events, id: :uuid do |t|
      t.string :name, null: false
      t.references :claim, foreign_key: true, type: :uuid, null: false
      t.references :actor, type: :uuid, foreign_key: {to_table: :dfe_sign_in_users}, null: true
      t.references :entity, polymorphic: true, type: :uuid, null: true

      t.timestamps
    end
  end
end
