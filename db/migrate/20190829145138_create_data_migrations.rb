class CreateDataMigrations < ActiveRecord::Migration[5.2]
  def change
    return if table_exists? :data_migrations
    create_table :data_migrations, primary_key: "version", id: :string
  end
end
