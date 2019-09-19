class CreateNotes < ActiveRecord::Migration[5.2]
  def change
    create_table :notes, id: :uuid do |t|
      t.references :claim, index: true, type: :uuid
      t.string :created_by
      t.text :body
      t.timestamps
    end
  end
end
