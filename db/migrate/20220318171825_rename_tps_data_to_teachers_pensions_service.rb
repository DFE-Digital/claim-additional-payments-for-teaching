class RenameTpsDataToTeachersPensionsService < ActiveRecord::Migration[6.0]
  def up
    remove_index :tps_data, name: "index_tps_data_on_teacher_reference_number_and_start_date"
    rename_table :tps_data, :teachers_pensions_service
    add_index :teachers_pensions_service, ["teacher_reference_number", "start_date"], name: "index_tps_data_on_teacher_reference_number_and_start_date", unique: true
  end

  def down
    remove_index :teachers_pensions_service, name: "index_tps_data_on_teacher_reference_number_and_start_date"
    rename_table :teachers_pensions_service, :tps_data
    add_index :tps_data, ["teacher_reference_number", "start_date"], name: "index_tps_data_on_teacher_reference_number_and_start_date"
  end
end
