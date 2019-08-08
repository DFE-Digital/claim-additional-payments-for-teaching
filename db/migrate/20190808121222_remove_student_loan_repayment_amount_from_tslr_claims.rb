class RemoveStudentLoanRepaymentAmountFromTslrClaims < ActiveRecord::Migration[5.2]
  def change
    change_table :tslr_claims do |t|
      t.remove :student_loan_repayment_amount
    end
  end
end
