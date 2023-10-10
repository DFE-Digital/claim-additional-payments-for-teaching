class AddTeacherIdUserInfoToClaims < ActiveRecord::Migration[7.0]
  def up
    add_column :claims, :teacher_id_user_info, :jsonb, default: {}
  end

  def down
    remove_column :claims, :teacher_id_user_info
  end
end
