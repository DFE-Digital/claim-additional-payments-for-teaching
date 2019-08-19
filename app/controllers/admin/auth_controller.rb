module Admin
  class AuthController < BaseAdminController
    DFE_SIGN_IN_ADMIN_ROLE_CODE = "teacher_payments_access"

    skip_before_action :ensure_authenticated_user

    def sign_in
    end

    def sign_out
      session.destroy
      redirect_to root_path, notice: "You've been signed out"
    end

    def callback
      authenticated_session = DfeSignIn::AuthenticatedSession.from_auth_hash(request.env.fetch("omniauth.auth"))

      if authenticated_session.role_codes.include?(DFE_SIGN_IN_ADMIN_ROLE_CODE)
        session[:user_id] = authenticated_session.user_id
        session[:organisation_id] = authenticated_session.organisation_id
        redirect_to admin_path
      else
        render "failure", status: :unauthorized
      end
    end

    def failure
    end
  end
end
