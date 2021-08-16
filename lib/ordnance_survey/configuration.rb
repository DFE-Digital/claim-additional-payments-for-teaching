module OrdnanceSurvey
  class Configuration
    class Client
      attr_accessor :api_key, :base_url, :params

      def initialize
        self.base_url = nil
        self.params = {}
      end
    end

    def client
      @client ||= Client.new
    end
  end
end
