class AddAcademicYearToFileUploads < ActiveRecord::Migration[8.0]
  def change
    add_column :file_uploads, :academic_year, :string, limit: 9
  end
end
