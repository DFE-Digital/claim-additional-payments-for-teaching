class CreateTpsData < ActiveRecord::Migration[6.0]
  def change
    create_table :tps_data, id: :uuid do |t|
      t.string :teacher_reference_number
      t.datetime :start_date
      t.datetime :end_date
      t.integer :la_urn
      t.integer :school_urn

      t.timestamps
    end
    add_index :tps_data, :teacher_reference_number
    add_index :tps_data, [:teacher_reference_number, :start_date], unique: true
  end
end
