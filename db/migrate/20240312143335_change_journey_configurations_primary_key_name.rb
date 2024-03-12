class ChangeJourneyConfigurationsPrimaryKeyName < ActiveRecord::Migration[7.0]

  # Fix for 20240224185849_rename_policy_configurations migration to ensure
  # subsequent migration rollbacks work correctly
  def up
    execute("ALTER INDEX policy_configurations_pkey RENAME TO journey_configurations_pkey")
  end

  def down
    execute("ALTER INDEX journey_configurations_pkey RENAME TO policy_configurations_pkey")
  end
end
