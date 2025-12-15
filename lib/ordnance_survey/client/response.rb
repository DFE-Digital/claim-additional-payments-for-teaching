module OrdnanceSurvey
  class Client::Response
    def initialize(response:)
      @body = nil
      self.response = response
    end

    def body
      return @body if !@body.nil? || (@body.nil? && @response.body.empty?)

      @body = JSON.parse(response.body, symbolize_names: true)
    end

    def code
      response.status.to_i
    end

    private

    attr_accessor :response
  end
end
