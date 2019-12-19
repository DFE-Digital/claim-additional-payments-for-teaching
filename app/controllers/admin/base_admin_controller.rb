module Admin
  class BaseAdminController < ApplicationController
    ADMIN_TIMEOUT_LENGTH_IN_MINUTES = 30

    layout "admin"

    before_action :end_expired_admin_sessions, :ensure_authenticated_user
    helper_method :admin_signed_in?, :admin_timeout_in_minutes, :service_operator_signed_in?

    private

    def admin_signed_in?
      session.key?(:user_id)
    end

    def admin_timeout_in_minutes
      ADMIN_TIMEOUT_LENGTH_IN_MINUTES
    end

    def admin_session_timed_out?
      admin_signed_in? && session[:last_seen_at] < admin_timeout_in_minutes.minutes.ago
    end

    def end_expired_admin_sessions
      if admin_session_timed_out?
        session.delete(:user_id)
        session.delete(:organisation_id)
        session.delete(:role_codes)
        flash[:notice] = "Your session has timed out due to inactivity, please sign-in again"
      end
    end

    def ensure_authenticated_user
      unless admin_signed_in?
        session[:requested_admin_path] = request.fullpath
        redirect_to admin_sign_in_path
      end
    end

    def admin_user
      @admin_user ||= DfeSignIn::User.find(session[:user_id])
    end

    def admin_session
      @admin_session ||= AdminSession.new(admin_user.dfe_sign_in_id, session[:organisation_id], session[:role_codes])
    end

    def service_operator_signed_in?
      admin_session.is_service_operator?
    end

    def payroll_operator_signed_in?
      admin_session.is_payroll_operator?
    end

    def support_agent_signed_in?
      admin_session.is_support_agent?
    end

    def ensure_service_team
      render "admin/auth/failure", status: :unauthorized unless service_operator_signed_in? || support_agent_signed_in?
    end

    def ensure_service_operator
      render "admin/auth/failure", status: :unauthorized unless service_operator_signed_in?
    end

    def ensure_payroll_operator
      render "admin/auth/failure", status: :unauthorized unless payroll_operator_signed_in?
    end
  end
end
