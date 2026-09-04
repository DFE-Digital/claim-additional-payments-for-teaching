module Policies
  module DataRetention
    class RemoveRecoveryRecordsJob < ApplicationJob
      def perform
        scope = Recovery.where(destroy_at: ..Date.today.beginning_of_day)

        scope.find_each(&:destroy!)
      end
    end
  end
end
