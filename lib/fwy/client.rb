module Fwy
  class Client
    attr_reader :adapter

    def initialize(adapter: Faraday.default_adapter, stubs: nil)
      @adapter = adapter
      # Test stubs for requests
      @stubs = stubs
    end

    def teacher
      TeacherResource.new(self)
    end

    def connection
      @connection ||= Faraday.new(ENV["FWY_BASE_URL"]) do |c|
        c.request :authorization, 'Bearer', Bearer.get_auth_token
        c.request :json
        c.response :json, content_type: "application/json"

        c.adapter adapter, @stubs
      end
    end
  end
end