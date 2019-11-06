class ApplicationController < ActionController::Base
  TIMEOUT_WARNING_LENGTH_IN_MINUTES = 2

  http_basic_authenticate_with(
    name: ENV["BASIC_AUTH_USERNAME"],
    password: ENV["BASIC_AUTH_PASSWORD"],
    if: -> { ENV["BASIC_AUTH_USERNAME"].present? },
  )

  after_action :update_last_seen_at

  helper_method :timeout_warning_in_minutes

  private

  def timeout_warning_in_minutes
    TIMEOUT_WARNING_LENGTH_IN_MINUTES
  end

  def update_last_seen_at
    session[:last_seen_at] = Time.zone.now
  end
end
