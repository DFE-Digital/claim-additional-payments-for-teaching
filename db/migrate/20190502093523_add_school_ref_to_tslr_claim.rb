class AddSchoolRefToTslrClaim < ActiveRecord::Migration[5.2]
  def change
    add_reference :tslr_claims, :claim_school, type: :uuid, foreign_key: {to_table: :schools}
  end
end
