class AddSanitiseNameForEytfiProvider < ActiveRecord::Migration[8.1]
  def change
    add_column :eligible_eytfi_providers, :sanitised_name, :citext, null: false, default: ""
  end
end
