Hmrc::Employments.configure do |config|
  config.base_url = ENV["HMRC_EMPLOYMENTS_BASE_URL"]
  config.client_id = ENV["HMRC_EMPLOYMENTS_CLIENT_ID"]
  config.client_secret = ENV["HMRC_EMPLOYMENTS_CLIENT_SECRET"]
  config.totp_secret = ENV["HMRC_EMPLOYMENTS_TOTP_SECRET"]
  config.enabled = ENV["HMRC_EMPLOYMENTS_ENABLED"] == "true"
end
