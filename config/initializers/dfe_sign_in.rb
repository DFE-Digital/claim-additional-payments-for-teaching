DfeSignIn.configure do |config|
  config.client_id = ENV["DFE_SIGN_IN_API_CLIENT_ID"]
  config.secret = ENV["DFE_SIGN_IN_API_SECRET"]
  config.base_url = ENV["DFE_SIGN_IN_API_ENDPOINT"]
end
