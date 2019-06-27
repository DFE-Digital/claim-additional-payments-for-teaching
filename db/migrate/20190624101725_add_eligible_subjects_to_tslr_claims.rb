class AddEligibleSubjectsToTslrClaims < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :biology_taught, :boolean, default: false
    add_column :tslr_claims, :chemistry_taught, :boolean, default: false
    add_column :tslr_claims, :physics_taught, :boolean, default: false
    add_column :tslr_claims, :computer_science_taught, :boolean, default: false
    add_column :tslr_claims, :languages_taught, :boolean, default: false
  end
end
