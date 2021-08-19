class RemoveNotesIndex < ActiveRecord::Migration[6.0]
  def change
    remove_index :notes, [:claim_id, :created_at]
  end
end
