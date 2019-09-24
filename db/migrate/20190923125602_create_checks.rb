class CreateChecks < ActiveRecord::Migration[5.2]
  def change
    create_table :checks, id: :uuid do |t|
      t.integer :result
      t.string :checked_by
      t.references :claim, index: true, type: :uuid
      t.timestamps
    end
  end
end
