class AddTeachingSubjectNowToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :early_career_payments_eligibilities, :teaching_subject_now, :boolean
  end
end
