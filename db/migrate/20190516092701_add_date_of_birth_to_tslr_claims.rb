class AddDateOfBirthToTslrClaims < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :date_of_birth, :date
  end
end
