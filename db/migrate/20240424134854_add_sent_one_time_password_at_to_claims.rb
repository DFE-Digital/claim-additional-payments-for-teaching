class AddSentOneTimePasswordAtToClaims < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :sent_one_time_password_at, :datetime
  end
end
