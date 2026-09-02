class ChangeJourneyConfigPkey < ActiveRecord::Migration[8.1]
  def up
    ApplicationRecord.connection.execute "ALTER TABLE journey_configurations DROP CONSTRAINT journey_configurations_pkey;"
    ApplicationRecord.connection.execute "ALTER TABLE journey_configurations ADD PRIMARY KEY (id);"
  end

  def down
    ApplicationRecord.connection.execute "ALTER TABLE journey_configurations DROP CONSTRAINT journey_configurations_pkey;"
    ApplicationRecord.connection.execute "ALTER TABLE journey_configurations ADD PRIMARY KEY (routing_name);"
  end
end
