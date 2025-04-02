module Admin
  class BaseAdminController < ApplicationController
    include AdminSessionTimeout
    include HttpAuthConcern

    layout "admin"

    before_action :end_expired_admin_sessions, :ensure_authenticated_user
    before_action :set_cache_headers
    after_action :update_last_seen_at
    helper_method :admin_signed_in?, :admin_timeout_in_minutes, :service_operator_signed_in?

    private

    def ensure_authenticated_user
      unless admin_signed_in?
        clear_session
        session[:requested_admin_path] = request.fullpath if store_requested_admin_path?
        redirect_to admin_sign_in_path
      end
    end

    def admin_user
      @admin_user ||= DfeSignIn::User.not_deleted.find_by(id: session[:user_id], session_token: session[:token])
    end

    def current_admin
      admin_user
    end
    helper_method :current_admin

    def service_operator_signed_in?
      admin_user.is_service_operator?
    end

    def payroll_operator_signed_in?
      admin_user.is_payroll_operator?
    end

    def support_agent_signed_in?
      admin_user.is_support_agent?
    end

    def ensure_service_team
      render "admin/auth/failure", status: :unauthorized unless service_operator_signed_in? || support_agent_signed_in?
    end

    def ensure_service_operator
      render "admin/auth/failure", status: :unauthorized unless service_operator_signed_in?
    end

    def ensure_payroll_operator
      render "admin/auth/failure", status: :unauthorized unless service_operator_signed_in? || payroll_operator_signed_in?
    end

    def update_last_seen_at
      session[:admin_last_seen_at] = Time.zone.now
    end

    def clear_session
      session.delete(:user_id)
      session.delete(:token)
      session.delete(:organisation_id)
      session.delete(:role_codes)
      session.delete(:claims_backlink_path)
    end

    def set_cache_headers
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
    end

    def store_requested_admin_path?
      true
    end
  end
end
