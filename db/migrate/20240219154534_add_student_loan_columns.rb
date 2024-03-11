# rubocop:disable Rails/ThreeStateBooleanColumn
class AddStudentLoanColumns < ActiveRecord::Migration[7.0]
  def change
    add_column :forms, :student_loan, :boolean
    # TODO: Add this back!
    # add_column :applicants, :student_loan, :boolean
  end
end
# rubocop:enable Rails/ThreeStateBooleanColumn
