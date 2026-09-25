module Hmrc
  class ResponseError < StandardError
    attr_reader :response

    def initialize(response = nil)
      @response = response
      super
    end
  end
end
