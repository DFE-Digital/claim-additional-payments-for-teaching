class AddUploadErrorsToFileUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :file_uploads, :upload_errors, :text, array: true, default: []
  end
end
