class AddPiiRemovedAtTimestamp < ActiveRecord::Migration[6.0]
  def change
    add_column :claims, :pii_removed_at, :timestamp
  end
end
