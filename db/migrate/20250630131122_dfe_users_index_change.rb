class DfeUsersIndexChange < ActiveRecord::Migration[8.0]
  def change
    remove_index :dfe_sign_in_users, :dfe_sign_in_id

    add_index :dfe_sign_in_users, [:dfe_sign_in_id, :user_type], unique: true
  end
end
