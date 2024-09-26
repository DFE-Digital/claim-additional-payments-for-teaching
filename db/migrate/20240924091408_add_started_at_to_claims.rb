class AddStartedAtToClaims < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :started_at, :timestamp
  end
end
