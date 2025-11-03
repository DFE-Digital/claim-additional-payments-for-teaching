class AddRepeatApplicantCheckPassedToFeEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column :further_education_payments_eligibilities,
      :repeat_applicant_check_passed,
      :boolean
  end
end
