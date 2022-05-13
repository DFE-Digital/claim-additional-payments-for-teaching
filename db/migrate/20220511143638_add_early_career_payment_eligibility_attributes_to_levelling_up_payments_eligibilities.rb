class AddEarlyCareerPaymentEligibilityAttributesToLevellingUpPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_column :levelling_up_payments_eligibilities, :nqt_in_academic_year_after_itt, :boolean
    add_column :levelling_up_payments_eligibilities, :employed_as_supply_teacher, :boolean
    add_column :levelling_up_payments_eligibilities, :qualification, :integer
    add_column :levelling_up_payments_eligibilities, :has_entire_term_contract, :boolean
    add_column :levelling_up_payments_eligibilities, :employed_directly, :boolean
    add_column :levelling_up_payments_eligibilities, :subject_to_disciplinary_action, :boolean
    add_column :levelling_up_payments_eligibilities, :subject_to_formal_performance_action, :boolean
    add_column :levelling_up_payments_eligibilities, :eligible_itt_subject, :integer
    add_column :levelling_up_payments_eligibilities, :teaching_subject_now, :boolean
    add_column :levelling_up_payments_eligibilities, :itt_academic_year, :string, limit: 9
    add_reference :levelling_up_payments_eligibilities, :current_school, type: :uuid, foreign_key: {to_table: :schools}, index: true
    add_column :levelling_up_payments_eligibilities, :award_amount, :decimal, precision: 7, scale: 2
    add_column :levelling_up_payments_eligibilities, :eligible_degree_subject, :boolean
  end
end
