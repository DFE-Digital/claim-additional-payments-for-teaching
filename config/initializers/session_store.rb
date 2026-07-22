domain = if Rails.env.review_app_like?
  ENV["CANONICAL_HOSTNAME"]
elsif !ENV["TID_BASE_URL"].nil?
  URI.parse(ENV["TID_BASE_URL"]).host
end

key = case ENV["ENVIRONMENT_NAME"]
when "test"
  "_test_claim_session"
when "staging"
  "_staging_claim_session"
else
  "_claim_session"
end

Rails.application.config.session_store :cookie_store, key:, domain:
