class PopulateStudentLoansEmployments < ActiveRecord::Migration[5.2]
  def up
    StudentLoans::Eligibility.left_joins(:employments).merge(StudentLoans::Employment.where(id: nil)).where.not(claim_school: nil).each do |eligibility|
      StudentLoans::Employment.create!(
        eligibility: eligibility,
        school: eligibility.claim_school,
        biology_taught: eligibility.biology_taught,
        chemistry_taught: eligibility.chemistry_taught,
        computer_science_taught: eligibility.computer_science_taught,
        languages_taught: eligibility.languages_taught,
        physics_taught: eligibility.physics_taught,
        taught_eligible_subjects: eligibility.taught_eligible_subjects,
        student_loan_repayment_amount: eligibility.student_loan_repayment_amount,
      )
    end
  end

  def down
    StudentLoans::Employment.delete_all
  end
end
