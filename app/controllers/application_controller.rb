class ApplicationController < ActionController::Base
  TIMEOUT_WARNING_LENGTH_IN_MINUTES = 2

  helper_method :timeout_warning_in_minutes

  def handle_unwanted_requests
    render file: Rails.root.join("public", "404.html"), status: :not_found, layout: false
  end

  private

  def timeout_warning_in_minutes
    TIMEOUT_WARNING_LENGTH_IN_MINUTES
  end
end
