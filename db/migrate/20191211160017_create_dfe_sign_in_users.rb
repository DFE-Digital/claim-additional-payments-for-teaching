class CreateDfeSignInUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :dfe_sign_in_users, id: :uuid do |t|
      t.string :dfe_sign_in_id, index: {unique: true}
      t.string :given_name
      t.string :family_name
      t.string :email
      t.string :organisation_name

      t.timestamps
    end
  end
end
