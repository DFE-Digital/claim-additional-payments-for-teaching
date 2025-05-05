class AddEligibleIttSubjectStringToTargetedRetentionIncentivePaymentsEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column :targeted_retention_incentive_payments_eligibilities, :eligible_itt_subject_string, :string
  end
end
