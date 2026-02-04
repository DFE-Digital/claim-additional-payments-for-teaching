module Dqt
  class Client
    attr_reader :adapter

    def initialize(adapter: Faraday.default_adapter)
      @adapter = adapter
    end

    def teacher
      TeacherResource.new(self)
    end

    def connection
      @connection ||= Faraday.new(ENV["DQT_API_URL"]) do |c|
        c.request :authorization, "Bearer", Bearer.get_auth_token
        c.request :json
        c.headers["X-Api-Version"] = "Next"
        c.response :json, content_type: "application/json"
        c.adapter adapter
      end
    end
  end
end
