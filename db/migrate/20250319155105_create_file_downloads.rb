class CreateFileDownloads < ActiveRecord::Migration[8.0]
  def change
    create_table :file_downloads, id: :uuid do |t|
      t.uuid :downloaded_by_id

      t.text :body
      t.string :filename
      t.string :content_type

      t.string :source_data_model
      t.string :source_data_model_id

      t.timestamps
    end
  end
end
