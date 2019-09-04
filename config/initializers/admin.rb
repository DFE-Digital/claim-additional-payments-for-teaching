require "rollbar/middleware/rack"

require_relative "../../lib/restrict_admin_by_ip_middleware"

Rails.application.configure do
  allowed_ips = ENV.fetch("ADMIN_ALLOWED_IPS").split(",")

  config.middleware.insert_after Rollbar::Middleware::Rails::RollbarMiddleware, RestrictAdminByIpMiddleware, allowed_ips
end
