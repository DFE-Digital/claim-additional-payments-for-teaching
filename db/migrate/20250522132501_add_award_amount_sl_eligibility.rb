class AddAwardAmountSlEligibility < ActiveRecord::Migration[8.0]
  def up
    add_column :student_loans_eligibilities, :award_amount, :decimal, precision: 7, scale: 2

    Policies::StudentLoans::Eligibility.reset_column_information

    Policies::StudentLoans::Eligibility.update_all("award_amount = student_loan_repayment_amount")
  end

  def down
    remove_column :student_loans_eligibilities, :award_amount
  end
end
