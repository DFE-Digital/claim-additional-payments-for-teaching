class AddQualificationStringToTargetedRetentionIncentivePaymentsEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column :targeted_retention_incentive_payments_eligibilities, :qualification_string, :string
  end
end
