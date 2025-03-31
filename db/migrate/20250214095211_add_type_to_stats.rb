class AddTypeToStats < ActiveRecord::Migration[8.0]
  def change
    add_column :stats, :type, :text
  end
end
