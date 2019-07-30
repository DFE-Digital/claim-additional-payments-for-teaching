class AddEligibilityReferenceToTslrClaims < ActiveRecord::Migration[5.2]
  def change
    change_table :tslr_claims do |t|
      t.references :eligibility, type: :uuid, polymorphic: true, index: true
    end
  end
end
