class AddRoleCodesToDfeSignInUser < ActiveRecord::Migration[6.0]
  def change
    add_column :dfe_sign_in_users, :role_codes, :string, array: true, default: []
  end
end
