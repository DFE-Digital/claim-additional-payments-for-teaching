class AddQualificationStringToEarlyCareerPaymentsEligibilities < ActiveRecord::Migration[8.0]
  def change
    add_column :early_career_payments_eligibilities, :qualification_string, :string
  end
end
