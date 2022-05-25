class ChangePolicyConfigurationPolicyType < ActiveRecord::Migration[6.0]
  def up
    add_column :policy_configurations, :policy_types, :text, array: true, default: []

    PolicyConfiguration.reset_column_information
    PolicyConfiguration.all.each do |pc|
      policy_types = [pc.policy_type]
      policy_types << "LevellingUpPremiumPayments" if pc.policy_type == "EarlyCareerPayments"
      pc.update!(policy_types: policy_types)
    end

    remove_column :policy_configurations, :policy_type
  end

  def down
    add_column :policy_configurations, :policy_type, :text

    PolicyConfiguration.reset_column_information
    PolicyConfiguration.all.each do |pc|
      pc.update!(policy_type: pc.policy_types.first)
    end

    change_column :policy_configurations, :policy_type, :text, null: false
    add_index :policy_configurations, :policy_type, unique: true

    remove_column :policy_configurations, :policy_types
  end
end
