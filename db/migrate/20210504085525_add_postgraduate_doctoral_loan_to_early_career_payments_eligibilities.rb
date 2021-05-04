class AddPostgraduateDoctoralLoanToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :early_career_payments_eligibilities, :postgraduate_doctoral_loan, :boolean
  end
end
