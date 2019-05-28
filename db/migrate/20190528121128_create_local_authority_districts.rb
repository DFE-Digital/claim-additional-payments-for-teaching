class CreateLocalAuthorityDistricts < ActiveRecord::Migration[5.2]
  def change
    create_table :local_authority_districts, id: :uuid do |t|
      t.string :name
      t.string :code

      t.index :code, unique: true
    end
  end
end
