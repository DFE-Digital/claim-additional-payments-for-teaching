class AddCurrentOrganisationUkprnToDfeSignInUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :dfe_sign_in_users, :current_organisation_ukprn, :string
  end
end
