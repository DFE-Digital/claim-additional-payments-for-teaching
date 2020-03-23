class MakeDecisionsUndoable < ActiveRecord::Migration[6.0]
  def change
    add_column :decisions, :undone, :boolean, default: false
  end
end
