class RenameEarlyCareerPaymentsEligibilitiesEnumColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :early_career_payments_eligibilities, :qualification
    remove_column :early_career_payments_eligibilities, :eligible_itt_subject

    Policies::EarlyCareerPayments::Eligibility.reset_column_information

    rename_column :early_career_payments_eligibilities, :qualification_string, :qualification
    rename_column :early_career_payments_eligibilities, :eligible_itt_subject_string, :eligible_itt_subject
  end
end
