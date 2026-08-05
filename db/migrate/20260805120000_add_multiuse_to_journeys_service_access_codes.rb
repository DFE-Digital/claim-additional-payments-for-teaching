class AddMultiuseToJourneysServiceAccessCodes < ActiveRecord::Migration[8.1]
  def change
    add_column :journeys_service_access_codes, :multiuse, :boolean, default: false, null: false
  end
end
