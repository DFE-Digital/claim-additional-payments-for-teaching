class CreateStatsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :stats, id: :uuid do |t|
      t.text :one_login_return_code

      t.timestamps
    end
  end
end
