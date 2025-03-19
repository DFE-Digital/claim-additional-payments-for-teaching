class RemoveExtraIndexes < ActiveRecord::Migration[8.0]
  def change
    remove_index :levelling_up_premium_payments_awards, column: :award_by_amount
    remove_index :journey_configurations, :created_at
  end
end
