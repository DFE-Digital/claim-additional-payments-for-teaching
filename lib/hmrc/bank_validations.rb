module Hmrc
  module BankValidations
    extend Hmrc::ClientConfiguration
  end
end

require_relative "bank_validations/bank_account_verification_response"
require_relative "bank_validations/personal_bank_account_verification_request"
require_relative "bank_validations/client"
require_relative "bank_validations/configuration"
