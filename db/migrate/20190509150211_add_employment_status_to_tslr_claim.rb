class AddEmploymentStatusToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :employment_status, :integer
    add_index :tslr_claims, :employment_status
  end
end
