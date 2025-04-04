class ApplicationController < ActionController::Base
  TIMEOUT_WARNING_LENGTH_IN_MINUTES = 2

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
end
