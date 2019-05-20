class AddNationalInsuranceNumberToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :national_insurance_number, :string, limit: 9
  end
end
