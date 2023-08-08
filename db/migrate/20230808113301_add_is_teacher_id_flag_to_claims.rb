class AddIsTeacherIdFlagToClaims < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :logged_in_with_tid, :boolean, default: false
  end
end
