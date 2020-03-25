class AddManualToChecks < ActiveRecord::Migration[6.0]
  def change
    add_column :tasks, :manual, :boolean
  end
end
