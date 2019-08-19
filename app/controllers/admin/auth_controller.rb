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
      if authorised?
        session[:admin_auth] = auth_hash.fetch("info").to_h
        redirect_to admin_path
      else
        render "failure", status: :unauthorized
      end
    end

    def failure
    end

    private

    def authorised?
      authenticated_session = DfeSignIn::AuthenticatedSession.from_auth_hash(auth_hash)
      authenticated_session.role_codes.include?(DFE_SIGN_IN_ADMIN_ROLE_CODE)
    end

    def auth_hash
      request.env.fetch("omniauth.auth")
    end
  end
end
