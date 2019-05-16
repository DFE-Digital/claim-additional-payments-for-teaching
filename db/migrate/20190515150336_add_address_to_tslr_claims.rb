class AddAddressToTslrClaims < ActiveRecord::Migration[5.2]
  def change
    change_table :tslr_claims do |t|
      t.string :address_line_1, limit: 100
      t.string :address_line_2, limit: 100
      t.string :address_line_3, limit: 100
      t.string :address_line_4, limit: 100
      t.string :postcode, limit: 11
    end
  end
end
