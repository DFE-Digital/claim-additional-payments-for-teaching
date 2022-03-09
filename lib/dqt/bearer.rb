module Dqt
  class Bearer
    class << self
      def get_auth_token
        ENV["DQT_API_KEY"]
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
