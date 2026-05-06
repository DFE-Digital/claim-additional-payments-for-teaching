class CreateEligibleEytfiProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :eligible_eytfi_providers, id: :uuid do |t|
      t.uuid "file_upload_id", null: false

      t.text :urn, null: false
      t.text :name, null: false
      t.text :address_line_1
      t.text :address_line_2
      t.text :address_line_3
      t.text :town
      t.text :postcode, null: false
      t.boolean :eligible, null: false

      t.timestamps
    end

    add_index :eligible_eytfi_providers, [:urn, :file_upload_id], unique: true
  end
end
