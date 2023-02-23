module Hmrc
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

require_relative "hmrc/bank_account_verification_response"
require_relative "hmrc/client"
require_relative "hmrc/configuration"
require_relative "hmrc/response_error"
