class ApplicationController < ActionController::Base
  include HttpAuthConcern

  TIMEOUT_WARNING_LENGTH_IN_MINUTES = 2

  helper_method :timeout_warning_in_minutes

  before_action :set_session
  
  private

  def timeout_warning_in_minutes
    TIMEOUT_WARNING_LENGTH_IN_MINUTES
  end

  def set_session
    SessionAccessor.session = cookies
  end
end
