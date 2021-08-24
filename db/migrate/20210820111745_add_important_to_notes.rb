class AddImportantToNotes < ActiveRecord::Migration[6.0]
  def change
    add_column :notes, :important, :boolean
  end
end
