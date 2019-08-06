class AddGenderToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :gender, :integer
  end
end
