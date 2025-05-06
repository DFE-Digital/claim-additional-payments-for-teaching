class AddEligibleIttSubjectStringToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column :early_career_payments_eligibilities, :eligible_itt_subject_string, :string
  end
end
