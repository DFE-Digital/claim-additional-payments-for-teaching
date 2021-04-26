module Dqt
  class Configuration
    class Client
      attr_accessor :headers, :host, :params, :port

      def initialize
        self.headers = {}
        self.host = nil
        self.params = {}
        self.port = nil
      end
    end

    def client
      @client ||= Client.new
    end
  end
end
