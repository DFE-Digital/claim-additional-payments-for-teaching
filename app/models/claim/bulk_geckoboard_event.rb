class Claim
  class BulkGeckoboardEvent < GeckoboardEvent
    attr_reader :data

    def initialize(event_type, data)
      @event_type = event_type
      @data = data
    end

    def record
      dataset.post(data)
    end
  end
end
