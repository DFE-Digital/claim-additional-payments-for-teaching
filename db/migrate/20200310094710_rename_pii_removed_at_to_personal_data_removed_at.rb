class RenamePiiRemovedAtToPersonalDataRemovedAt < ActiveRecord::Migration[6.0]
  def change
    rename_column :claims, :pii_removed_at, :personal_data_removed_at
  end
end
