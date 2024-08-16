class AddOneloginFieldsToClaims < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :identity_confirmed_with_onelogin, :boolean
    add_column :claims, :logged_in_with_onelogin, :boolean
    add_column :claims, :onelogin_credentials, :jsonb, default: {}
    add_column :claims, :onelogin_user_info, :jsonb, default: {}
  end
end
