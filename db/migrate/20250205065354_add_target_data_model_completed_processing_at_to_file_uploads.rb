class AddTargetDataModelCompletedProcessingAtToFileUploads < ActiveRecord::Migration[8.0]
  def change
    add_column :file_uploads, :target_data_model, :string
    add_column :file_uploads, :completed_processing_at, :datetime
  end
end
