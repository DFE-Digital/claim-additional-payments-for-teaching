class AddStudentLoanRepaymentAmountToStudentLoansEligibilities < ActiveRecord::Migration[5.2]
  def change
    add_column :student_loans_eligibilities, :student_loan_repayment_amount, :decimal, precision: 7, scale: 2
  end
end
