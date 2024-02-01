class AddIndexToPolicyConfigurationsPolicyTypes < ActiveRecord::Migration[7.0]
  def change
    add_index :policy_configurations, :policy_types
  end
end
