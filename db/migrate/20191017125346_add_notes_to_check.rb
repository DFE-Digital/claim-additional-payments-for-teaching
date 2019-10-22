class AddNotesToCheck < ActiveRecord::Migration[5.2]
  def change
    add_column :checks, :notes, :text
  end
end
