class MakeClaimPractitionerEmailAddressCitext < ActiveRecord::Migration[7.0]
  def change
    enable_extension "citext"

    reversible do |dir|
      dir.up do
        change_column :claims, :practitioner_email_address, :citext
      end

      dir.down do
        change_column :claims, :practitioner_email_address, :string
      end
    end
  end
end
