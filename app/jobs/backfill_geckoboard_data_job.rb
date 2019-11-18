class BackfillGeckoboardDataJob < ApplicationJob
  def perform(event_type, data)
    Claim::BulkGeckoboardEvent.new(event_type, data).record
  end
end
