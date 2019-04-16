class CreateSchools < ActiveRecord::Migration[5.2]
  def change
    create_table :schools, id: :uuid do |t|
      t.integer :urn, null: false
      t.string :name, null: false
      t.string :street
      t.string :locality
      t.string :town
      t.string :county
      t.string :postcode
      t.integer :phase, null: false
      t.integer :school_type_group, null: false
      t.integer :school_type, null: false

      t.references :local_authority, index: true, type: :uuid

      t.timestamps

      t.index :urn, unique: true
    end
  end
end
