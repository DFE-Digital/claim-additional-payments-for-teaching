module DfeSignIn
  class UserDataImporter
    def run
      users = DfeSignIn::Api::User.all
      users.each do |u|
        user = DfeSignIn::User.find_or_initialize_by(dfe_sign_in_id: u.user_id)

        user.given_name = u.given_name
        user.family_name = u.family_name
        user.email = u.email
        user.organisation_name = u.organisation_name

        user.save!
      end
    end
  end
end
