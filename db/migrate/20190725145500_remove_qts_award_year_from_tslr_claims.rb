class RemoveQtsAwardYearFromTslrClaims < ActiveRecord::Migration[5.2]
  def change
    remove_column :tslr_claims, :qts_award_year, :integer
  end
end
