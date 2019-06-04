class AddBankDetailsToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_column :tslr_claims, :bank_sort_code, :string, limit: 6
    add_column :tslr_claims, :bank_account_number, :string, limit: 8
  end
end
