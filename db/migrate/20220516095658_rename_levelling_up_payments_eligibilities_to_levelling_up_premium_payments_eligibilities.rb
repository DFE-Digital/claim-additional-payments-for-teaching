class RenameLevellingUpPaymentsEligibilitiesToLevellingUpPremiumPaymentsEligibilities < ActiveRecord::Migration[6.0]
  def change
    rename_index :levelling_up_payments_eligibilities, "index_levelling_up_payments_eligibilities_on_current_school_id", "index_lup_payments_eligibilities_on_current_school_id"
    rename_table "levelling_up_payments_eligibilities", "levelling_up_premium_payments_eligibilities"
  end
end
