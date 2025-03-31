class CreateTargetedRetentionIncentivePaymentsEligibilities < ActiveRecord::Migration[8.0]
  def change
    create_table :targeted_retention_incentive_payments_eligibilities, id: :uuid, if_not_exists: true do |t|
      t.boolean :nqt_in_academic_year_after_itt
      t.boolean :employed_as_supply_teacher
      t.integer :qualification
      t.boolean :has_entire_term_contract
      t.boolean :employed_directly
      t.boolean :subject_to_disciplinary_action
      t.boolean :subject_to_formal_performance_action
      t.integer :eligible_itt_subject
      t.boolean :teaching_subject_now
      t.string :itt_academic_year, limit: 9
      t.uuid :current_school_id
      t.decimal :award_amount, precision: 7, scale: 2
      t.boolean :eligible_degree_subject
      t.boolean :induction_completed
      t.boolean :school_somewhere_else
      t.string :teacher_reference_number, limit: 11

      t.timestamps
    end

    add_index :targeted_retention_incentive_payments_eligibilities, :current_school_id, if_not_exists: true
    add_index :targeted_retention_incentive_payments_eligibilities, :teacher_reference_number, if_not_exists: true
  end
end
