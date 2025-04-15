class RenameSchoolsEnumColumns < ActiveRecord::Migration[8.0]
  def up
    remove_column :schools, :phase
    remove_column :schools, :school_type_group
    remove_column :schools, :school_type

    School.reset_column_information

    rename_column :schools, :phase_string, :phase
    rename_column :schools, :school_type_group_string, :school_type_group
    rename_column :schools, :school_type_string, :school_type

    School.reset_column_information

    change_column_null :schools, :phase, false
    change_column_null :schools, :school_type_group, false
    change_column_null :schools, :school_type, false
  end
end
