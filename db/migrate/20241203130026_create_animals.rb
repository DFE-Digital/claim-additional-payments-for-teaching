class CreateAnimals < ActiveRecord::Migration[8.0]
  def change
    create_table :animals, id: :uuid do |t|
      t.timestamps
    end
  end
end
