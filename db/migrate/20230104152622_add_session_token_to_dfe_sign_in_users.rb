class AddSessionTokenToDfeSignInUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :dfe_sign_in_users, :session_token, :string
    add_index :dfe_sign_in_users, :session_token, unique: true
  end
end
