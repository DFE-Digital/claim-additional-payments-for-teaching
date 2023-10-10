class AddLabelToNotes < ActiveRecord::Migration[7.0]
  def change
    add_column :notes, :label, :string
    add_index :notes, [:label, :claim_id], unique: false
  end
end
