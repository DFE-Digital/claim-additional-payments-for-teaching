class AddEnumStringsToSchools < ActiveRecord::Migration[8.0]
  def change
    add_column :schools, :phase_string, :string
    add_column :schools, :school_type_group_string, :string
    add_column :schools, :school_type_string, :string
  end
end
