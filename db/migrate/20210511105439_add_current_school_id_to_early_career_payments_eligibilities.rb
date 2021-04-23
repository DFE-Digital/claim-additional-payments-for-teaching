class AddCurrentSchoolIdToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    add_reference :early_career_payments_eligibilities, :current_school, type: :uuid, foreign_key: {to_table: :schools}
  end
end
