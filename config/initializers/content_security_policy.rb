# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src :self, :https, :data
  policy.img_src :self, :https, :data
  policy.object_src :none
  policy.script_src :self, "https://www.googletagmanager.com/gtm.js"
  policy.script_src_elem :self, "https://www.googletagmanager.com/gtm.js"
  policy.connect_src :self, "https://www.google-analytics.com"

  if Rails.env.review_app_like?
    policy.style_src :self, :https, "'unsafe-inline'"
    policy.script_src :self, :https, "https://www.googletagmanager.com/gtm.js"
    policy.script_src_elem :self, :https, "https://www.googletagmanager.com/gtm.js"
  else
    policy.style_src :self
  end

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end

Rails.application.config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
Rails.application.config.content_security_policy_nonce_directives = %w[script-src script-src-elem]
# Rails.application.configure do
#   config.content_security_policy do |policy|
#     policy.default_src :self, :https
#     policy.font_src    :self, :https, :data
#     policy.img_src     :self, :https, :data
#     policy.object_src  :none
#     policy.script_src  :self, :https
#     policy.style_src   :self, :https
#     # Specify URI for violation reports
#     # policy.report_uri "/csp-violation-report-endpoint"
#   end
#
#   # Generate session nonces for permitted importmap and inline scripts
#   config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
#   config.content_security_policy_nonce_directives = %w(script-src)
#
#   # Report violations without enforcing the policy.
#   # config.content_security_policy_report_only = true
# end
