class AddEligibleIttSubjectToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :early_career_payments_eligibilities, :eligible_itt_subject, :integer
  end
end
