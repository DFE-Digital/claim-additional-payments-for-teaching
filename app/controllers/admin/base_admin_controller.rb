module Admin
  class BaseAdminController < ApplicationController
    include AdminSessionTimeout

    layout "admin"

    before_action :end_expired_admin_sessions, :ensure_authenticated_user
    after_action :update_last_seen_at
    helper_method :admin_signed_in?, :admin_timeout_in_minutes, :service_operator_signed_in?

    private

    def ensure_authenticated_user
      unless true
        session[:requested_admin_path] = request.fullpath
        redirect_to admin_sign_in_path
      end
    end

    def admin_user
      @admin_user ||= DfeSignIn::User.find(session[:user_id])
    end

    def service_operator_signed_in?
      return true 
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
      render "admin/auth/failure", status: :unauthorized unless payroll_operator_signed_in?
    end

    def update_last_seen_at
      session[:admin_last_seen_at] = Time.zone.now
    end
  end
end
