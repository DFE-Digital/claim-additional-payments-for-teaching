require "dfe_sign_in"

DfeSignIn.configure do |config|
  config.client_id = ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID")
  config.secret = Rails.env.production? ? ENV.fetch("DFE_SIGN_IN_API_SECRET") : ENV.fetch("DFE_SIGN_IN_API_SECRET", "secret")
  config.base_url = ENV.fetch("DFE_SIGN_IN_API_ENDPOINT")
end

DfeSignIn.configure do |config|
  config.client_id = ENV.fetch("DFE_SIGN_IN_INTERNAL_CLIENT_ID", "foo")
  config.secret = ENV.fetch("DFE_SIGN_IN_INTERNAL_API_SECRET", "bar")
  config.base_url = ENV.fetch("DFE_SIGN_IN_API_ENDPOINT")
end
