class CreateLocalAuthorities < ActiveRecord::Migration[5.2]
  def change
    create_table :local_authorities, id: :uuid do |t|
      t.integer :code
      t.string :name

      t.index :code, unique: true
    end
  end
end
