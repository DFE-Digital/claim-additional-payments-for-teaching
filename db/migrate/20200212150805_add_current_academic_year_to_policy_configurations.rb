class AddCurrentAcademicYearToPolicyConfigurations < ActiveRecord::Migration[6.0]
  def change
    add_column :policy_configurations, :current_academic_year, :string, limit: 9
  end
end
