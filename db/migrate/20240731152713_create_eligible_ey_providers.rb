class CreateEligibleEyProviders < ActiveRecord::Migration[7.0]
  def change
    create_table :eligible_ey_providers, id: :uuid do |t|
      t.string :nursery_name
      t.string :urn
      t.references :local_authority, null: false, foreign_key: true, type: :uuid
      t.string :nursery_address
      t.string :primary_key_contact_email_address
      t.string :secondary_contact_email_address

      t.timestamps
    end
    add_index :eligible_ey_providers, :urn
  end
end
