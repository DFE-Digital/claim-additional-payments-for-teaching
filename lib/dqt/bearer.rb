module Dqt
  class Bearer
    class << self
      def get_auth_token
        connection.post(ENV["DQT_BEARER_BASE_URL"], {
          grant_type: ENV["DQT_BEARER_GRANT_TYPE"],
          scope: ENV["DQT_BEARER_SCOPE"],
          client_id: ENV["DQT_BEARER_CLIENT_ID"],
          client_secret: ENV["DQT_BEARER_CLIENT_SECRET"]
        }).body["access_token"]
      end

      def connection
        Faraday.new(ENV["DQT_BASE_URL"]) do |c|
          c.request :url_encoded
          c.response :json
          c.adapter Faraday.default_adapter
        end
      end
    end
  end
end
