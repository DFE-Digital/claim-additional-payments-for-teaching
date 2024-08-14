class AddAnswerFieldsToFeEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :further_education_payments_eligibilities, :teaching_responsibilities, :boolean
    add_column :further_education_payments_eligibilities, :provision_search, :text
    add_reference :further_education_payments_eligibilities, :possible_school, type: :uuid, foreign_key: {to_table: :schools}, index: {name: :index_fe_payments_eligibilities_on_possible_school_id}
    add_reference :further_education_payments_eligibilities, :school, type: :uuid, foreign_key: {to_table: :schools}, index: {name: :index_fe_payments_eligibilities_on_school_id}
    add_column :further_education_payments_eligibilities, :contract_type, :text
    add_column :further_education_payments_eligibilities, :fixed_term_full_year, :boolean
    add_column :further_education_payments_eligibilities, :taught_at_least_one_term, :boolean
    add_column :further_education_payments_eligibilities, :teaching_hours_per_week, :text
    add_column :further_education_payments_eligibilities, :teaching_hours_per_week_next_term, :text
    add_column :further_education_payments_eligibilities, :further_education_teaching_start_year, :text
    add_column :further_education_payments_eligibilities, :subjects_taught, :jsonb, default: []
    add_column :further_education_payments_eligibilities, :building_construction_courses, :jsonb, default: []
    add_column :further_education_payments_eligibilities, :chemistry_courses, :jsonb, default: []
    add_column :further_education_payments_eligibilities, :computing_courses, :jsonb, default: []
    add_column :further_education_payments_eligibilities, :early_years_courses, :jsonb, default: []
    add_column :further_education_payments_eligibilities, :engineering_manufacturing_courses, :jsonb, default: []
    add_column :further_education_payments_eligibilities, :maths_courses, :jsonb, default: []
    add_column :further_education_payments_eligibilities, :physics_courses, :jsonb, default: []
    add_column :further_education_payments_eligibilities, :hours_teaching_eligible_subjects, :boolean
    add_column :further_education_payments_eligibilities, :teaching_qualification, :text
    add_column :further_education_payments_eligibilities, :subject_to_formal_performance_action, :boolean
    add_column :further_education_payments_eligibilities, :subject_to_disciplinary_action, :boolean
    add_column :further_education_payments_eligibilities, :half_teaching_hours, :boolean
  end
end
