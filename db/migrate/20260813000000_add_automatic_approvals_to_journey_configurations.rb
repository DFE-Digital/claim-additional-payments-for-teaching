class AddAutomaticApprovalsToJourneyConfigurations < ActiveRecord::Migration[7.0]
  def change
    add_column :journey_configurations, :automatic_approvals, :boolean, default: true, null: false
  end
end
