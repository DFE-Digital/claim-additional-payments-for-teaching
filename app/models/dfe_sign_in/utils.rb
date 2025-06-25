module DfeSignIn
  module Utils
    def generate_jwt_token
      payload = {
        iss: DfeSignIn.configuration_for_client_id(ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID")).client_id,
        exp: (Time.now.getlocal + 60).to_i,
        aud: "signin.education.gov.uk"
      }
      JWT.encode(payload, DfeSignIn.configuration_for_client_id(ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID")).secret, "HS256")
    end

    def get(uri)
      response = dfe_sign_in_request(uri)

      raise ExternalServerError, "#{response.code}: #{response.body}" unless response.code.eql?("200")

      JSON.parse(response.body)
    end

    def dfe_sign_in_request(uri)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "bearer #{generate_jwt_token}"
      request["Content-Type"] = "application/json"

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
        http.request(request)
      }
    end
  end
end
