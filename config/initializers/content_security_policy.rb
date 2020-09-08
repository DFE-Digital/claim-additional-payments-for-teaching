# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src :self, :https, :data
  policy.img_src :self, "https://v2assets.zopim.io", "https://static.zdassets.com", :https, :data
  policy.object_src :none
  policy.script_src :self, "https://static.zdassets.com"
  policy.connect_src :self, "https://www.google-analytics.com", "https://ekr.zdassets.com", "https://static.zdassets.com", "https://additional-teaching-payment.zendesk.com", "wss://additional-teaching-payment.zendesk.com", "wss://*.zopim.com"
  policy.style_src :self, :unsafe_inline

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator =
# -> request { SecureRandom.base64(16) }

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
