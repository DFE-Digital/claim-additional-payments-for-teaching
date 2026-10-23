class AddConfigurableQaThresholds < ActiveRecord::Migration[8.1]
  def change
    add_column :journey_configurations, :approved_min_qa_threshold, :integer, default: 100
    add_column :journey_configurations, :rejected_min_qa_threshold, :integer, default: 100
  end
end
