module DfeSignIn
  class UserDataImporter
    attr_reader :user_type

    def initialize(user_type:)
      raise "invalid user_type: #{user_type}" if DfeSignIn::User::USER_TYPES.exclude?(user_type)

      @user_type = user_type
    end

    def run
      create_or_update_users
      delete_users
    end

    private

    def client_id
      @client_id ||= DfeSignIn::User.client_id_for_user_type(user_type)
    end

    def create_or_update_users
      api_users = DfeSignIn::Api::User.all(client_id:)

      api_users.each do |u|
        user = DfeSignIn::User
          .where(user_type:)
          .find_or_initialize_by(dfe_sign_in_id: u.user_id)

        user.given_name = u.given_name
        user.family_name = u.family_name
        user.email = u.email
        user.organisation_name = u.organisation_name
        user.deleted_at = nil

        user.save!
      end
    end

    def delete_users
      DfeSignIn::User
        .where(user_type:)
        .where(dfe_sign_in_id: users_no_longer_present)
        .each(&:mark_as_deleted!)
    end

    def users_no_longer_present
      persisted_user_ids = DfeSignIn::User
        .where(user_type:)
        .pluck(:dfe_sign_in_id)
        .compact

      expected_user_ids = DfeSignIn::Api::User.all(client_id:).map(&:user_id).compact

      persisted_user_ids - expected_user_ids
    end
  end
end
