class RemoveExtraIndexesOnTargetedRetentionIncentivePaymentsAwards < ActiveRecord::Migration[8.0]
  def up
    remove_index :targeted_retention_incentive_payments_awards, name: :idx_on_award_amount_327151d288
  end

  def down
    add_index :targeted_retention_incentive_payments_awards, :award_amount, name: :idx_on_award_amount_327151d288
  end
end
