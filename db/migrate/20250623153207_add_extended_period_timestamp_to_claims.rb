class AddExtendedPeriodTimestampToClaims < ActiveRecord::Migration[8.0]
  def change
    add_column :claims, :retained_personal_data_removed_at, :datetime
  end
end
