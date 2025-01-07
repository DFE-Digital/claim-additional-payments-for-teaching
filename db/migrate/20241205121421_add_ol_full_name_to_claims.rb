class AddOlFullNameToClaims < ActiveRecord::Migration[8.0]
  def up
    add_column :claims, :onelogin_idv_full_name, :text

    execute <<-SQL
      UPDATE claims
      SET onelogin_idv_full_name = CONCAT(claims.onelogin_idv_first_name, ' ', claims.onelogin_idv_last_name)
      WHERE claims.onelogin_idv_full_name IS NULL
    SQL
  end

  def down
    remove_column :claims, :onelogin_idv_full_name
  end
end
