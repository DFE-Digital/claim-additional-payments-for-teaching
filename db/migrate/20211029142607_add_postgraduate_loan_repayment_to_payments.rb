class AddPostgraduateLoanRepaymentToPayments < ActiveRecord::Migration[6.0]
  def change
    add_column :payments, :postgraduate_loan_repayment, :decimal, precision: 7, scale: 2
  end
end
