class AddRolesDfeUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :dfe_sign_in_users, :roles, :jsonb, default: []
  end
end
