class CreateFileUploads < ActiveRecord::Migration[6.1]
  def change
    create_table :file_uploads, id: :uuid do |t|
      t.uuid :uploaded_by_id
      t.text :body

      t.timestamps
    end
  end
end
