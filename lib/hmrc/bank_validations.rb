module Hmrc
  module BankValidations
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

  def self.client
    @client ||= BankValidations::Client.new
  end

  def self.client=(client)
    @client = client
  end

  def self.configuration
    @configuration ||= BankValidations::Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end
end

require_relative "base_client"
require_relative "bank_validations/bank_account_verification_response"
require_relative "bank_validations/client"
require_relative "bank_validations/configuration"
require_relative "bank_validations/response_error"

HmrcBankValidations = Hmrc::BankValidations
Hmrc::Client = Hmrc::BankValidations::Client unless defined?(Hmrc::Client)
Hmrc::Configuration = Hmrc::BankValidations::Configuration unless defined?(Hmrc::Configuration)
