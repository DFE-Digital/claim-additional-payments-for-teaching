module Admin
  class BaseAdminController < ApplicationController
    DFE_SIGN_IN_ADMIN_ROLE_CODE = "teacher_payments_access"
    DFE_SIGN_IN_SUPPORT_ROLE_CODE = "teacher_payments_support"

    before_action :ensure_authenticated_user
    helper_method :is_admin_user?, :is_support_user?

    def is_admin_user?
      is_user_of_type?(DFE_SIGN_IN_ADMIN_ROLE_CODE)
    end

    def is_support_user?
      is_user_of_type?(DFE_SIGN_IN_SUPPORT_ROLE_CODE)
    end

    private

    def is_user_of_type?(type)
      session[:role_codes].include?(type)
    end

    def ensure_authenticated_user
      redirect_to admin_sign_in_path unless admin_signed_in?
    end
  end
end
