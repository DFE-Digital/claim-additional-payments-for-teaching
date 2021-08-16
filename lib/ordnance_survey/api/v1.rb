require_relative "v1/search_places"

module OrdnanceSurvey
  class Api
    class V1
      def initialize(client:)
        self.client = client
      end

      def search_places
        @search_places ||= SearchPlaces.new(client: client)
      end

      private

      attr_accessor :client
    end
  end
end
