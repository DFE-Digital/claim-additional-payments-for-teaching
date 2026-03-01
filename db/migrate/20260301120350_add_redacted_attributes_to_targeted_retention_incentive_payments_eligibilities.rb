class AddRedactedAttributesToTargetedRetentionIncentivePaymentsEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_column :targeted_retention_incentive_payments_eligibilities, :redacted_attributes, :jsonb
  end
end
