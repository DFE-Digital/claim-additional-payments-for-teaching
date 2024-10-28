class AddVerifiedAtTimestampToClaims < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :verified_at, :datetime
  end
end
