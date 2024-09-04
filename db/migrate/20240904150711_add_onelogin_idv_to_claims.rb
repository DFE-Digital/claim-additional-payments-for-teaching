class AddOneloginIdvToClaims < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :onelogin_uid, :text
    add_column :claims, :onelogin_auth_at, :datetime
    add_column :claims, :onelogin_idv_at, :datetime
    add_column :claims, :onelogin_idv_first_name, :text
    add_column :claims, :onelogin_idv_last_name, :text
    add_column :claims, :onelogin_idv_date_of_birth, :date
  end
end
