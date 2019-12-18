module DfeSignIn
  module Api
    class User
      include DfeSignIn::Utils
      extend DfeSignIn::Utils

      attr_accessor :organisation_id,
        :user_id,
        :organisation_name,
        :given_name,
        :family_name,
        :email

      class << self
        def all
          get_users.map do |u|
            new(
              organisation_id: u["organisation"]["id"],
              organisation_name: u["organisation"]["name"],
              user_id: u["userId"],
              given_name: u["givenName"],
              family_name: u["familyName"],
              email: u["email"]
            )
          end
        end

        def all_users_endpoint
          URI.join(DfeSignIn.configuration.base_url, "/users")
        end

        def get_users
          uri = all_users_endpoint
          body = get(uri)
          page_number = 2
          users = body["users"]
          while page_number <= body["numberOfPages"]
            uri.query = "page=#{page_number}"
            page = get(uri)
            users.concat(page["users"])
            page_number += 1
          end
          users
        end
      end

      def initialize(attrs)
        self.organisation_id = attrs[:organisation_id]
        self.organisation_name = attrs[:organisation_name]
        self.user_id = attrs[:user_id]
        self.given_name = attrs[:given_name]
        self.family_name = attrs[:family_name]
        self.email = attrs[:email]
      end

      def has_role?(role_code)
        role_codes.include?(role_code)
      end

      def role_codes
        body["roles"].map { |r| r["code"] }
      end

      private

      def body
        @body ||= get(uri)
      end

      def uri
        @uri ||= begin
          uri = URI(DfeSignIn.configuration.base_url)
          uri.path = "/services/#{DfeSignIn.configuration.client_id}/organisations/#{organisation_id}/users/#{user_id}"
          uri
        end
      end
    end
  end
end
