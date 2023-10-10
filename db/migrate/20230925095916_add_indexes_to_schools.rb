class AddIndexesToSchools < ActiveRecord::Migration[7.0]
  def up
    add_column :schools, :postcode_sanitised, :string

    execute("UPDATE schools SET postcode_sanitised=REPLACE(postcode, ' ', '')")

    enable_extension "pg_trgm"
    add_index :schools, :name, using: "gin", opclass: :gin_trgm_ops
    add_index :schools, :postcode_sanitised, using: "gin", opclass: :gin_trgm_ops
  end

  def down
    remove_column :schools, :postcode_sanitised
    remove_index :schools, :name
  end
end
