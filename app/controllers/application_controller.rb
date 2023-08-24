class ApplicationController < ActionController::Base
  include HttpAuthConcern

  before_action :set_session

  TIMEOUT_WARNING_LENGTH_IN_MINUTES = 2

  helper_method :timeout_warning_in_minutes

  private

  def timeout_warning_in_minutes
    TIMEOUT_WARNING_LENGTH_IN_MINUTES
  end

  def set_session
    SessionAccessor.session = session
  end
end
