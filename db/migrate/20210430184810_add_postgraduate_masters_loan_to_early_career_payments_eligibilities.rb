class AddPostgraduateMastersLoanToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :early_career_payments_eligibilities, :postgraduate_masters_loan, :boolean
  end
end
