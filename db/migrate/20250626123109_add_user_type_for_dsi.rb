class AddUserTypeForDsi < ActiveRecord::Migration[8.0]
  def up
    add_column :dfe_sign_in_users, :user_type, :text
    add_index :dfe_sign_in_users, :user_type

    DfeSignIn::User.reset_column_information

    DfeSignIn::User
      .where("email ilike '%@education.gov.uk'")
      .update_all(user_type: "admin")

    DfeSignIn::User
      .where(user_type: nil)
      .update_all(user_type: "provider")
  end

  def down
    remove_column :dfe_sign_in_users, :user_type
  end
end
