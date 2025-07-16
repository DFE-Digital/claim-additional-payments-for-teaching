module DfeSignIn
  module Api
    class Client
      attr_reader :client_id

      # we use multiple accounts with DfE sign in
      # use relevant client_id to connect to required account
      def initialize(client_id:)
        @client_id = client_id
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

      def role_codes_for_user(user)
        get_user(user)["roles"].map { |r| r["code"] }
      end

      def dfe_sign_in_request(uri)
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "bearer #{generate_jwt_token}"
        request["Content-Type"] = "application/json"

        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
          http.request(request)
        }
      end

      def service_access_for_user?(user)
        uri = URI(base_url)
        uri.path = "/services/#{client_id}/organisations/#{user.organisation_id}/users/#{user.user_id}"
        response = dfe_sign_in_request(uri)
        response.code == "200"
      end

      private

      def get_user(user)
        uri = URI(base_url)
        uri.path = "/services/#{client_id}/organisations/#{user.organisation_id}/users/#{user.user_id}"
        get(uri)
      end

      def config
        @config ||= DfeSignIn.configuration_for_client_id(client_id)
      end

      def secret
        config.secret
      end

      def base_url
        config.base_url
      end

      def generate_jwt_token
        payload = {
          iss: client_id,
          exp: (Time.now.getlocal + 60).to_i,
          aud: "signin.education.gov.uk"
        }
        JWT.encode(payload, secret, "HS256")
      end

      def all_users_endpoint
        URI.join(base_url, "/users")
      end

      def get(uri)
        response = dfe_sign_in_request(uri)

        raise ExternalServerError, "#{response.code}: #{response.body}" unless response.code.eql?("200")

        JSON.parse(response.body)
      end
    end
  end
end
