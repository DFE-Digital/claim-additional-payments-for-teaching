class RenameTargetedRetentionIncentivePaymentsEligibilitiesEnumColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :targeted_retention_incentive_payments_eligibilities, :qualification
    remove_column :targeted_retention_incentive_payments_eligibilities, :eligible_itt_subject

    Policies::TargetedRetentionIncentivePayments::Eligibility.reset_column_information

    rename_column :targeted_retention_incentive_payments_eligibilities, :qualification_string, :qualification
    rename_column :targeted_retention_incentive_payments_eligibilities, :eligible_itt_subject_string, :eligible_itt_subject
  end
end
