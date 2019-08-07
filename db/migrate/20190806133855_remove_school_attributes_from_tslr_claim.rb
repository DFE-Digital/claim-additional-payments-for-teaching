class RemoveSchoolAttributesFromTslrClaim < ActiveRecord::Migration[5.2]
  def change
    change_table :tslr_claims do |t|
      t.remove :current_school_id
      t.remove :claim_school_id
      t.remove :employment_status
    end
  end
end
