require "logger"
require "faraday"

module Hmrc
  class ResponseError < StandardError
    attr_reader :response

    def initialize(response = nil)
      @response = response
      super(response.respond_to?(:body) ? response.body : response.to_s)
    end
  end

  module ClientConfiguration
    def client
      @client ||= const_get(:Client).new
    end

    def client=(client)
      @client = client
    end

    def configuration
      @configuration ||= const_get(:Configuration).new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end

require_relative "hmrc/base_client"
require_relative "hmrc/bank_validations"
require_relative "hmrc/employments"
