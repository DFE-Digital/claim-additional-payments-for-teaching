domain = if ENV["ENVIRONMENT_NAME"].start_with?("review")
  ENV["CANONICAL_HOSTNAME"]
elsif !ENV["TID_BASE_URL"].nil?
  URI.parse(ENV["TID_BASE_URL"]).host
end

key = if ENV["ENVIRONMENT_NAME"] == "test"
  "_test_claim_session"
else
  "_claim_session"
end

Rails.application.config.session_store :cookie_store, key:, domain:
