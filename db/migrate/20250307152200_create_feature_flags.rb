class CreateFeatureFlags < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_flags, id: :uuid do |t|
      t.text :name, null: false
      t.boolean :enabled, default: false, null: false

      t.timestamps
    end

    add_index :feature_flags, :name, unique: true
  end
end
