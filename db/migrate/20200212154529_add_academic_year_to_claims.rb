class AddAcademicYearToClaims < ActiveRecord::Migration[6.0]
  def change
    add_column :claims, :academic_year, :string, limit: 9
    add_index :claims, :academic_year
  end
end
