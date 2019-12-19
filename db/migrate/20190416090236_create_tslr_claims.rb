class CreateTslrClaims < ActiveRecord::Migration[5.2]
  def change
    enable_extension "pgcrypto"

    create_table :tslr_claims, id: :uuid do |t|
      t.string :qts_award_year

      t.timestamps
    end
  end
end
