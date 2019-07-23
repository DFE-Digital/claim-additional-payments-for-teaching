DfeSignIn.configure do |config|
  config.client_id = ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID")
  config.secret = ENV.fetch("DFE_SIGN_IN_API_SECRET")
  config.base_url = ENV.fetch("DFE_SIGN_IN_API_ENDPOINT")
end
