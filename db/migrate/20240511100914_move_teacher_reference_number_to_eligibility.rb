class MoveTeacherReferenceNumberToEligibility < ActiveRecord::Migration[7.0]
  def change
    add_column :early_career_payments_eligibilities, :teacher_reference_number, :string, limit: 11
    add_column :levelling_up_premium_payments_eligibilities, :teacher_reference_number, :string, limit: 11
    add_column :student_loans_eligibilities, :teacher_reference_number, :string, limit: 11

    add_index :early_career_payments_eligibilities, :teacher_reference_number, name: "index_ecp_eligibility_trn"
    add_index :levelling_up_premium_payments_eligibilities, :teacher_reference_number, name: "index_lupp_eligibility_trn"
    add_index :student_loans_eligibilities, :teacher_reference_number, name: "index_sl_eligibility_trn"

    # Copy teacher_reference_number from Claim to Eligibility
    Claim.all.includes(:eligibility).each do |claim|
      claim.eligibility.update!(teacher_reference_number: claim.teacher_reference_number)
    end

    # Keep the old column but rename it so it's not accidentally used, needs removing soon after migration is successful
    rename_column :claims, :teacher_reference_number, :column_to_remove_teacher_reference_number
  end
end
