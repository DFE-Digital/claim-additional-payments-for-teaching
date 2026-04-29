class AddUploadErrorsToFileUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :file_uploads, :upload_errors, :jsonb, default: []
  end
end
