module Dqt
  class Client::Response
    delegate :code, to: :response

    def initialize(response:)
      @body = nil
      self.response = response
    end

    def body
      return @body if !@body.nil? || (@body.nil? && @response.body.empty?)

      @body = JSON.parse(response.body, symbolize_names: true)
    end

    private

    attr_accessor :response
  end
end
