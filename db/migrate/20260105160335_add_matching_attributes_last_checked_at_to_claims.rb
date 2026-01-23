class AddMatchingAttributesLastCheckedAtToClaims < ActiveRecord::Migration[8.1]
  def change
    add_column :claims, :matching_attributes_last_checked_at, :timestamp
  end
end
