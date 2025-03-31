class MigrateLupToTri < ActiveRecord::Migration[8.0]
  def up
    execute("INSERT INTO targeted_retention_incentive_payments_awards (id, academic_year, school_urn, award_amount, file_upload_id, created_at, updated_at) SELECT id, academic_year, school_urn, award_amount, file_upload_id, created_at, updated_at FROM levelling_up_premium_payments_awards")
    execute("INSERT INTO targeted_retention_incentive_payments_eligibilities (id, nqt_in_academic_year_after_itt, employed_as_supply_teacher, qualification, has_entire_term_contract, employed_directly, subject_to_disciplinary_action, subject_to_formal_performance_action, eligible_itt_subject, teaching_subject_now, itt_academic_year, current_school_id, award_amount, eligible_degree_subject, induction_completed, school_somewhere_else, teacher_reference_number, created_at, updated_at) SELECT id, nqt_in_academic_year_after_itt, employed_as_supply_teacher, qualification, has_entire_term_contract, employed_directly, subject_to_disciplinary_action, subject_to_formal_performance_action, eligible_itt_subject, teaching_subject_now, itt_academic_year, current_school_id, award_amount, eligible_degree_subject, induction_completed, school_somewhere_else, teacher_reference_number, created_at, updated_at FROM levelling_up_premium_payments_eligibilities")
  end

  def down
    execute("TRUNCATE TABLE targeted_retention_incentive_payments_awards")
    execute("TRUNCATE TABLE targeted_retention_incentive_payments_eligibilities")
  end
end
