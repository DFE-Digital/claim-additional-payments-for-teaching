class AddRedactedAttributesToClaims < ActiveRecord::Migration[8.1]
  def change
    add_column :claims, :redacted_attributes, :jsonb
  end
end
