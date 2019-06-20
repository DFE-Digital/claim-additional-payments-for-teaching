class ApplicationController < ActionController::Base
  http_basic_authenticate_with(
    name: ENV["BASIC_AUTH_USERNAME"],
    password: ENV["BASIC_AUTH_PASSWORD"],
    if: -> { ENV.key?("BASIC_AUTH_USERNAME") },
  )

  helper_method :signed_in?, :govuk_verify_enabled?

  def signed_in?
    session.key?(:login)
  end

  def govuk_verify_enabled?
    ENV["GOVUK_VERIFY_ENABLED"]
  end
end
