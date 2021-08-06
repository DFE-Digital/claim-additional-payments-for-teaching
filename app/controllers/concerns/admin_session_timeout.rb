module AdminSessionTimeout
  ADMIN_TIMEOUT_LENGTH_IN_MINUTES = 60

  def end_expired_admin_sessions
    if admin_session_timed_out?
      session.delete(:user_id)
      session.delete(:organisation_id)
      session.delete(:role_codes)
      flash[:notice] = "Your session has timed out due to inactivity, please sign-in again"
    end
  end

  def admin_signed_in?
    session.key?(:user_id)
  end

  def admin_session_timed_out?
    admin_signed_in? && session[:admin_last_seen_at] < admin_timeout_in_minutes.minutes.ago
  end

  def admin_timeout_in_minutes
    ADMIN_TIMEOUT_LENGTH_IN_MINUTES
  end
end
