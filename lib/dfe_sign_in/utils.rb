module DfeSignIn
  module Utils
    def generate_jwt_token
      payload = {
        iss: DfeSignIn.configuration.client_id,
        exp: (Time.now.getlocal + 60).to_i,
        aud: "signin.education.gov.uk",
      }
      JWT.encode(payload, DfeSignIn.configuration.secret, "HS256")
    end

    def get(uri)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "bearer #{generate_jwt_token}"
      request["Content-Type"] = "application/json"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
        http.request(request)
      }

      raise ExternalServerError, "#{response.code}: #{response.body}" unless response.code.eql?("200")

      JSON.parse(response.body)
    end
  end
end
