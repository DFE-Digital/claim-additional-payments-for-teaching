class CreateCats < ActiveRecord::Migration[8.0]
  def change
    create_table :cats, id: :uuid do |t|
      t.timestamps
    end
  end
end
