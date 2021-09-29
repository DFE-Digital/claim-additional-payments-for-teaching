require_relative "qualified_teaching_status"

module Dqt
  class Api
    class V1
      class QualifiedTeachingStatuses
        def initialize(client:)
          self.client = client
        end

        def show(params:)
          mapped_params = {
            trn: params[:teacher_reference_number],
            ni: params[:national_insurance_number]
          }

          response = client.get(path: "/api/qualified-teachers/qualified-teaching-status", params: mapped_params)

          return nil unless response.respond_to?(:map)

          response[:data].map { |qualified_teaching_status| QualifiedTeachingStatus.new(response: qualified_teaching_status) }
        end

        private

        attr_accessor :client
      end
    end
  end
end
