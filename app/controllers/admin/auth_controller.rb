module Admin
  class AuthController < BaseAdminController
    skip_before_action :ensure_authenticated_user

    def sign_in
    end

    def sign_out
      session.destroy
      redirect_to root_path, notice: "You've been signed out"
    end

    def callback
      admin_session = AdminSession.from_auth_hash(request.env.fetch("omniauth.auth"))

      if admin_session.has_admin_access?
        session[:user_id] = admin_session.user_id
        session[:organisation_id] = admin_session.organisation_id
        session[:role_codes] = admin_session.role_codes
        redirect_to admin_root_path
      else
        render "failure", status: :unauthorized
      end
    end

    def failure
    end
  end
end
