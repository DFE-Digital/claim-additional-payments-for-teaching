class AddUsedToJourneysServiceAccessCodes < ActiveRecord::Migration[8.0]
  def change
    add_column :journeys_service_access_codes, :used, :boolean, default: false, null: false
  end
end
