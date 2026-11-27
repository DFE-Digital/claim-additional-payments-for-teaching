class CreateCaches < ActiveRecord::Migration[8.1]
  def change
    create_table :caches, id: :uuid do |t|
      t.citext :key, null: false
      t.text :value
      t.datetime :expires_at

      t.timestamps
    end

    add_index :caches, :key, unique: true
  end
end
