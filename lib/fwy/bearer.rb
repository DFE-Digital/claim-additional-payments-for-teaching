module Fwy
  class Bearer
    class << self
      def get_auth_token
        connection.post(ENV['FWY_BEARER_BASE_URL'], { 
          grant_type: ENV['FWY_BEARER_GRANT_TYPE'],
          scope: ENV['FWY_BEARER_SCOPE'],
          client_id: ENV['FWY_BEARER_CLIENT_ID'],
          client_secret: ENV['FWY_BEARER_CLIENT_SECRET']
        }).body['access_token']
      end
  
      def connection
        Faraday.new(ENV["FWY_BASE_URL"]) do |c|
          c.request :url_encoded
          c.response :json #, content_type: "application/json"
          c.adapter Faraday.default_adapter
        end
      end
    end
  end
end