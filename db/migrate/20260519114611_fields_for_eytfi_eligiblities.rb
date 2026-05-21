class FieldsForEytfiEligiblities < ActiveRecord::Migration[8.1]
  def change
    add_column :early_years_teachers_financial_incentive_payments_eligibilities,
      :teacher_auth_teacher_reference_number, :text

    add_column :early_years_teachers_financial_incentive_payments_eligibilities,
      :teacher_auth_email, :citext

    add_column :early_years_teachers_financial_incentive_payments_eligibilities,
      :teacher_auth_verified_name, :citext

    add_column :early_years_teachers_financial_incentive_payments_eligibilities,
      :teacher_auth_verified_date_of_birth, :date

    add_column :early_years_teachers_financial_incentive_payments_eligibilities,
      :teacher_auth_one_login_uid, :text

    add_column :early_years_teachers_financial_incentive_payments_eligibilities,
      :teacher_auth_completed_at, :datetime

    add_column :early_years_teachers_financial_incentive_payments_eligibilities,
      :nursery_id, :text

    add_column :early_years_teachers_financial_incentive_payments_eligibilities,
      :teaching_qualification_confirmation, :boolean

    add_column :early_years_teachers_financial_incentive_payments_eligibilities,
      :confirmed_employment_proof_blob_ids, :text, array: true, default: []

    add_column :early_years_teachers_financial_incentive_payments_eligibilities,
      :has_eligible_qualification, :boolean

    add_column :early_years_teachers_financial_incentive_payments_eligibilities,
      :continue_claim, :boolean
  end
end
