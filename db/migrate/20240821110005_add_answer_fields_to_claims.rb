class AddAnswerFieldsToClaims < ActiveRecord::Migration[7.0]
  def change
    add_column :claims, :paye_reference, :string
    add_column :claims, :practitioner_email_address, :string
    add_column :claims, :provider_contact_name, :string
  end
end
