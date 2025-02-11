class AddResultBooleanToDecisions < ActiveRecord::Migration[8.0]
  def change
    add_column :decisions, :approved, :boolean
  end
end
