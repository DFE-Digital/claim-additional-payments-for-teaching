module DfeSignIn
  class UserAccess
    include DfeSignIn::Utils

    attr_accessor :organisation_id,
                  :user_id

    def initialize(organisation_id:, user_id:)
      self.organisation_id = organisation_id
      self.user_id = user_id
    end

    def has_role?(role)
      roles.include?(role)
    end

    private

    def body
      @body ||= begin
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "bearer #{generate_jwt_token}"
        request["Content-Type"] = "application/json"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
          http.request(request)
        }

        raise ExternalServerError if response.code.eql?("500")

        JSON.parse(response.body) if response.code.eql?("200")
      end
    end

    def roles
      body["roles"].map { |r| r["code"] }
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
