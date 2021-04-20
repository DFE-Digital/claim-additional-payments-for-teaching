class AddSubjectToDisciplinaryActionToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :early_career_payments_eligibilities, :subject_to_disciplinary_action, :boolean
  end
end
