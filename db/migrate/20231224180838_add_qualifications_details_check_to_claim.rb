class AddQualificationsDetailsCheckToClaim < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :dqt_teacher_status, :jsonb, default: nil
    add_column :claims, :qualifications_details_check, :boolean, default: nil
  end
end
