module DfeSignIn
  module Api
    class User
      attr_accessor :organisation_id,
        :user_id,
        :organisation_name,
        :given_name,
        :family_name,
        :email,
        :user_type

      class << self
        def all(client_id:)
          client = Client.new(client_id:)

          client.get_users.map do |u|
            new(
              organisation_id: u["organisation"]["id"],
              organisation_name: u["organisation"]["name"],
              user_id: u["userId"],
              given_name: u["givenName"],
              family_name: u["familyName"],
              email: u["email"],
              user_type: DfeSignIn::User.user_type_for_client_id(client_id)
            )
          end
        end
      end

      def initialize(attrs)
        self.organisation_id = attrs[:organisation_id]
        self.organisation_name = attrs[:organisation_name]
        self.user_id = attrs[:user_id]
        self.given_name = attrs[:given_name]
        self.family_name = attrs[:family_name]
        self.email = attrs[:email]
        self.user_type = attrs[:user_type]
      end

      def client_id
        DfeSignIn::User.client_id_for_user_type(user_type)
      end

      def has_role?(role_code)
        role_codes.include?(role_code)
      end

      def role_codes
        # TODO: this is hard coded to single client_id
        # need to make change so we know which client id we are using
        client = Client.new(client_id:)
        client.role_codes_for_user(self)
      end

      def service_access?
        client = Client.new(client_id:)
        client.service_access_for_user?(self)
      end
    end
  end
end
