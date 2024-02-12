class AddSchoolSomewhereElseToEligibility < ActiveRecord::Migration[7.0]
  def change
    add_column :early_career_payments_eligibilities, :school_somewhere_else, :boolean, default: nil
    add_column :levelling_up_premium_payments_eligibilities, :school_somewhere_else, :boolean, default: nil
  end
end
