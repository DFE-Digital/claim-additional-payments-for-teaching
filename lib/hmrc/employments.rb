module Hmrc
  module Employments
    def self.client
      @client ||= Client.new
    end

    def self.client=(client)
      @client = client
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration) if block_given?
    end
  end
end

HmrcEmployments = Hmrc::Employments

require_relative "base_client"
require_relative "employments/client"
require_relative "employments/configuration"
require_relative "employments/matching_request"
require_relative "employments/employment_history_request"
