class ApplicationController < ActionController::Base
  TIMEOUT_WARNING_LENGTH_IN_MINUTES = 2

  before_action :set_security_headers

  helper_method :timeout_warning_in_minutes
  protect_from_forgery except: :handle_unwanted_requests

  def handle_unwanted_requests
    if request.head?
      head :bad_request
    else
      render file: Rails.root.join("public", "404.html"), status: :not_found, layout: false
    end
  end

  private

  def timeout_warning_in_minutes
    TIMEOUT_WARNING_LENGTH_IN_MINUTES
  end

  def set_security_headers
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"
    response.headers["X-Frame-Options"] = "SAMEORIGIN"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-XSS-Protection"] = "1; mode=block"
  end
end
