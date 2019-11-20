class ChangeComputerScienceTaughtToComputingTaught < ActiveRecord::Migration[6.0]
  def change
    rename_column :student_loans_eligibilities, :computer_science_taught, :computing_taught
  end
end
