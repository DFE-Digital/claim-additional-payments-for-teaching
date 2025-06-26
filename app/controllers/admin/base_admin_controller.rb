module Admin
  class BaseAdminController < ApplicationController
    ADMIN_TIMEOUT_LENGTH_IN_MINUTES = 60

    include HttpAuthConcern

    layout "admin"

    before_action :end_expired_admin_sessions
    before_action :ensure_authenticated_user
    before_action :set_cache_headers
    after_action :update_last_seen_at
    helper_method :admin_signed_in?, :admin_timeout_in_minutes, :service_operator_signed_in?

    private

    def ensure_authenticated_user
      if current_admin.null_user?
        clear_session
        session[:requested_admin_path] = request.fullpath if store_requested_admin_path?
        redirect_to admin_sign_in_path
      end
    end

    def admin_user
      @admin_user ||= DfeSignIn::User.admin.not_deleted.find_by(id: session[:user_id], session_token: session[:token]) || DfeSignIn::NullUser.new
    end

    def current_admin
      admin_user
    end
    helper_method :current_admin

    def service_operator_signed_in?
      admin_user.is_service_operator?
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

    def ensure_service_admin
      render "admin/auth/failure", status: :unauthorized unless current_admin.is_service_admin?
    end

    def update_last_seen_at
      session[:admin_last_seen_at] = Time.zone.now
    end

    def clear_session
      @admin_user = nil

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

    def end_expired_admin_sessions
      if admin_session_timed_out?
        clear_session
        flash[:notice] = "Your session has timed out due to inactivity, please sign-in again"
      end
    end

    def admin_signed_in?
      session.key?(:user_id) && admin_user.present?
    end

    def admin_session_timed_out?
      admin_signed_in? && session[:admin_last_seen_at] < admin_timeout_in_minutes.minutes.ago
    end

    def admin_timeout_in_minutes
      ADMIN_TIMEOUT_LENGTH_IN_MINUTES
    end
  end
end
