class CreateTslrClaims < ActiveRecord::Migration[5.2]
  def change
    create_table :tslr_claims do |t|
      t.timestamps
    end
  end
end
