class RemovePostgraduateLoansFromEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    remove_column :early_career_payments_eligibilities, :postgraduate_masters_loan, type: :boolean
    remove_column :early_career_payments_eligibilities, :postgraduate_doctoral_loan, type: :boolean
  end
end
