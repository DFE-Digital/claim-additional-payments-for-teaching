class DropRepeatApplicantCheckColumn < ActiveRecord::Migration[8.1]
  def change
    remove_column(
      :further_education_payments_eligibilities,
      :repeat_applicant_check_passed,
      :boolean
    )
  end
end
