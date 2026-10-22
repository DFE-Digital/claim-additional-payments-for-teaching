class RenameDataRetentionRecoveryTable < ActiveRecord::Migration[8.1]
  def change
    rename_table(
      :policies_data_retention_recoveries,
      :data_retention_recoveries
    )
  end
end
