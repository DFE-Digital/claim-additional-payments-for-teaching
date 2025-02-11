class DropDecisionsResult < ActiveRecord::Migration[8.0]
  def change
    remove_column :decisions, :result, :integer
  end
end
