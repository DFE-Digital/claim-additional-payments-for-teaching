class CreateEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    create_table :early_career_payments_eligibilities, id: :uuid do |t|
      t.boolean "nqt_in_academic_year_after_itt"
      t.timestamps
    end
  end
end
