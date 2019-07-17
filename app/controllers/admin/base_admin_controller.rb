module Admin
  class BaseAdminController < ApplicationController
    TIMEOUT_LENGTH_IN_MINUTES = 30

    before_action :ensure_authenticated_user, :end_expired_sessions, :update_last_seen_at

    private

    def ensure_authenticated_user
      redirect_to admin_sign_in_path unless signed_in?
    end

    def end_expired_sessions
      if admin_session_timed_out?
        session.destroy
        redirect_to admin_sign_in_path, notice: "Your session has timed out due to inactivity, please sign-in again"
      end
    end

    def admin_session_timed_out?
      signed_in? && session.key?(:last_seen_at) &&
        session[:last_seen_at] < TIMEOUT_LENGTH_IN_MINUTES.minutes.ago
    end
  end
end
