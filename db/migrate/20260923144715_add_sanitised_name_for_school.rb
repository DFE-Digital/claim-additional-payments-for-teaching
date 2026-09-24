class AddSanitisedNameForSchool < ActiveRecord::Migration[8.1]
  def change
    add_column :schools, :name_sanitised, :citext, default: "", null: false
  end
end
