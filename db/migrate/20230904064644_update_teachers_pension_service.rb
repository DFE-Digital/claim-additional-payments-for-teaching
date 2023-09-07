class UpdateTeachersPensionService < ActiveRecord::Migration[7.0]
  def change
    add_column :teachers_pensions_service, :nino, :string
    add_column :teachers_pensions_service, :employer_id, :integer
  end
end
