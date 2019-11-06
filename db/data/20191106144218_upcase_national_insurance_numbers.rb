class UpcaseNationalInsuranceNumbers < ActiveRecord::Migration[5.2]
  def up
    Claim.update_all("national_insurance_number = upper(national_insurance_number)")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
