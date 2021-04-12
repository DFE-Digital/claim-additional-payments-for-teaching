require_relative "v1/qualified_teaching_status"

module Dqt
  class Api
    class V1
      def initialize(client:)
        self.client = client
      end

      def qualified_teaching_status
        @qualified_teaching_status ||= QualifiedTeachingStatus.new(client: client)
      end

      private

      attr_accessor :client
    end
  end
end
