class CreatePolicyConfigurations < ActiveRecord::Migration[5.2]
  def change
    create_table :policy_configurations, id: :uuid do |t|
      t.string :policy_type, null: false
      t.boolean :open_for_submissions, default: true, null: false
      t.string :availability_message

      t.timestamps

      t.index :policy_type, unique: true
    end
  end
end
