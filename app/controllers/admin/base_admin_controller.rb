module Admin
  class BaseAdminController < ApplicationController
    layout "admin"

    before_action :ensure_authenticated_user
    helper_method :service_operator_signed_in?

    private

    def ensure_authenticated_user
      redirect_to admin_sign_in_path unless admin_signed_in?
    end

    def admin_session
      @admin_session ||= AdminSession.new(session[:user_id], session[:organisation_id], session[:role_codes])
    end

    def service_operator_signed_in?
      admin_session.is_service_operator?
    end

    def ensure_service_operator
      render "admin/auth/failure", status: :unauthorized unless service_operator_signed_in?
    end
  end
end
