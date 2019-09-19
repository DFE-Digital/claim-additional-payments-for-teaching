class DropRedundantFullNameColumnFromClaims < ActiveRecord::Migration[5.2]
  def change
    remove_column :claims, :full_name, :string, limit: 200
  end
end
