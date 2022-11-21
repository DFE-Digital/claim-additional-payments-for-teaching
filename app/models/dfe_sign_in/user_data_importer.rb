module DfeSignIn
  class UserDataImporter
    attr_reader :dfe_sign_in_users

    def initialize
      @dfe_sign_in_users = DfeSignIn::Api::User.all
    end

    def run
      create_or_update_users
      delete_users
    end

    private

    def create_or_update_users
      dfe_sign_in_users.each do |u|
        user = DfeSignIn::User.find_or_initialize_by(dfe_sign_in_id: u.user_id)

        user.given_name = u.given_name
        user.family_name = u.family_name
        user.email = u.email
        user.organisation_name = u.organisation_name

        user.save!
      end
    end

    def delete_users
      DfeSignIn::User.where(dfe_sign_in_id: users_no_longer_present).each(&:mark_as_deleted!)
    end

    def users_no_longer_present
      DfeSignIn::User.all.map(&:dfe_sign_in_id) - dfe_sign_in_users.map(&:user_id)
    end
  end
end
