class AddDeletedAtToDfeSignInUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_column :dfe_sign_in_users, :deleted_at, :datetime
    add_index :dfe_sign_in_users, :deleted_at, algorithm: :concurrently
  end
end
