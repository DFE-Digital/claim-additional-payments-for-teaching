module Dqt
  class Api
    delegate :qualified_teaching_status, to: :v1

    def initialize(client:)
      self.client = client
      self.v1 = nil
    end

    def v1
      @v1 ||= V1.new(client: client)
    end

    private

    attr_accessor :client
    attr_writer :v1
  end
end
