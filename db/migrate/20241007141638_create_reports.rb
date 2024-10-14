class CreateReports < ActiveRecord::Migration[7.0]
  def change
    create_table :reports, id: :uuid do |t|
      t.string :name
      t.text :csv
      t.integer :number_of_rows

      t.timestamps
    end
  end
end
