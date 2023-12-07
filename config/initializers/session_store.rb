domain = if ENV["ENVIRONMENT_NAME"] == "review"
  ENV["CANONICAL_HOSTNAME"]
elsif !ENV["TID_BASE_URL"].nil?
  URI.parse(ENV["TID_BASE_URL"]).host
end

Rails.application.config.session_store :cookie_store, key: "_claim_session", domain:
