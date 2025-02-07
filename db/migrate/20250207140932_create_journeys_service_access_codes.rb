class CreateJourneysServiceAccessCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :journeys_service_access_codes, id: :uuid do |t|
      t.string :code, null: false, index: {unique: true}
      t.string :journey, null: false

      t.timestamps
    end
  end
end
