class AddInductionCompletedToEcpAndLupEligibilities < ActiveRecord::Migration[7.0]
  def change
    add_column :early_career_payments_eligibilities, :induction_completed, :boolean
    add_column :levelling_up_premium_payments_eligibilities, :induction_completed, :boolean
  end
end
