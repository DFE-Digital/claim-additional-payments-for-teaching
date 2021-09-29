require_relative "v1/qualified_teaching_statuses"

module Dqt
  class Api
    class V1
      def initialize(client:)
        self.client = client
      end

      def qualified_teaching_statuses
        @qualified_teaching_statuses ||= QualifiedTeachingStatuses.new(client: client)
      end

      private

      attr_accessor :client
    end
  end
end
